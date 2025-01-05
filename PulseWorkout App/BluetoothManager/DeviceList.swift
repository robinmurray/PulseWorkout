//
//  DeviceList.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 23/03/2023.
//

import Foundation
import CoreBluetooth
import CloudKit
import os

let defaultBTDevices: [BTDevice] = [BTDevice(id: UUID(uuidString: "B1D7C9D0-12AC-FABC-FC29-B00EDE23F68E")!, name: "TICKR C703", services: [], deviceInfo: [:])]


enum DeviceConnectionState {
    case disconnected, connecting, connected
}


struct BTDevice: Identifiable, Codable {
    var id: UUID
    var name: String
    var services: [String]
    var connectionState: DeviceConnectionState?
    var deviceInfo: [String:String]
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "BTDevice")
    
    // set CodingKeys to exclude connectionState from coding/decoding
    private enum CodingKeys: String, CodingKey {
        case id, name, services, deviceInfo
    }

    func serviceDescriptions() -> [String] {
        
        var returnVal: [String] = []
        for service in services {
            returnVal.append(BTServices[service, default: service])
        }
        return returnVal
    }


    /// Set device info the device
    /// Return true / false whether the deviceInfo has changed
    mutating func setDeviceInfo(key: String, value: String) -> Bool {
        if let currentInfo = deviceInfo[key] {
            if currentInfo == value {
                return false
            }
        }
        deviceInfo[key] = value
        return true
    }
    
    func connected(bluetoothManager: BTDevicesController) -> Bool {
        
        for peripheral in bluetoothManager.activePeripherals {
            
            if peripheral.identifier == id {
                
                return peripheral.state == CBPeripheralState.connected

            }
        }
        return false
    }
    
    
    /// Create CKRecord.ID for this device
    func CKRecordID() -> CKRecord.ID {
        let zoneName = DataCache.zoneName
        return CKRecord.ID(recordName: id.uuidString, zoneID: CKRecordZone.ID(zoneName: zoneName))
    }
    
    
    /// Convert device data to CKRecord
    func asCKRecord() -> CKRecord {
        let recordType = "BTDevices"
        let recordID: CKRecord.ID = CKRecordID()
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["name"] = name as CKRecordValue
        record["services"] = services as CKRecordValue
        
        do {
            let data = try JSONEncoder().encode(deviceInfo)
            let jsonString = String(data: data, encoding: .utf8) ?? ""
            record["deviceInfo"] = jsonString as CKRecordValue
        } catch {
            logger.error("Error enconding deviceInfo")
        }

        return record
    }


}

struct DeviceList: CustomStringConvertible {
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "BTDeviceList")
    let cloudKitManager = CloudKitManager()
        
    var description: String {
        return "Device List description <HERE>"
    }
    
    var devices: [BTDevice]
    
    /// Whether the list is persistent and stored to Cloudkit & UserDefaults
    /// Set to true for knownDevices
    var persistent: Bool = false
    
    /// Key for storing persistent list in user defaults
    var userDefaultsKey: String?
    
    var serviceConnectCallback: [CBUUID: (Bool) -> Void] = [:]

    
    func deviceFromPeripheral(peripheral: CBPeripheral) -> BTDevice {
        
        return BTDevice(id: peripheral.identifier, name: peripheral.name ?? "Unknown", services: [], deviceInfo: [:])
    }
    
    
    func deviceFromCKRecord(record: CKRecord) -> BTDevice? {
        
        var deviceInfo: [String:String] = [:]
        var name: String = ""
        var services: [String] = []
        
        if record.recordType != "BTDevices" {
            logger.error("Incorrect record type for BT Device")
            return nil
        }

        guard let id = UUID(uuidString: record.recordID.recordName) else {
            logger.error("Failed to decode id for record \(record)")
            return nil
        }
        
        name = record["name"] ?? "" as String
        services = record["services"] ?? [] as [String]
        
        let jsonDeviceInfo = record["deviceInfo"] ?? "" as String
        let jsonData = (jsonDeviceInfo as! String).data(using: .utf8) ?? Data()

        let decoder = JSONDecoder()
        if let tempDeviceInfo = try? decoder.decode(type(of: deviceInfo), from: jsonData) {
            deviceInfo = tempDeviceInfo
        }
        
        logger.info("read device \(id)  :  \(name)  :  \(services)  :  \(deviceInfo)")
        return BTDevice(id: id,
                        name: name,
                        services: services,
                        deviceInfo: deviceInfo)
        
    }
    
    
    func empty() -> Bool {
        return devices.count == 0
    }
    
    
    mutating func setDefault() {
        devices = defaultBTDevices
        if persistent {
            saveAndDeleteRecord(recordsToSave: devices.map( {$0.asCKRecord()} ),
                                recordIDsToDelete: [])
            write()
        }
    }
    
    
    /// Add device to this device list
    /// If device list is persistent, write to cloudkit and UserDefaults
    mutating func add(device: BTDevice) {
        
        if let _ = devices.firstIndex(where: { $0.id == device.id }) {
            return
        }
        devices.append(device)
        
        if persistent {
            saveAndDeleteRecord(recordsToSave: [device.asCKRecord()],
                                recordIDsToDelete: [])
            write()
        }
    }
    
    
    /// Add device represented by the BT peripheral to this device list
    /// If device list is persistent, write to cloudkit and UserDefaults
    mutating func add(peripheral: CBPeripheral) {
        
        if let _ = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            return
        }
        add(device: deviceFromPeripheral(peripheral: peripheral))

    }
    
    
    /// Remove device from this device list
    /// If device list is persistent, write to cloudkit and UserDefaults
    mutating func remove(device: BTDevice) {
        
        if let index = devices.firstIndex(where: { $0.id == device.id }) {

            devices.remove(at: index)
            
            if persistent {
                saveAndDeleteRecord(recordsToSave: [],
                                    recordIDsToDelete: [device.CKRecordID()])
                write()
            }
        }
    }
    
    
    /// Remove device represented by this BT Peripheral from this device list
    /// If device list is persistent, write to cloudkit and UserDefaults
    mutating func remove(peripheral: CBPeripheral) {
        
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            let IDToRemove = devices[index].CKRecordID()
            devices.remove(at: index)
            
            if persistent {
                saveAndDeleteRecord(recordsToSave: [],
                                    recordIDsToDelete: [IDToRemove])
                write()
            }
        }
    }
    
    
    /// Does the device list contain this device
    func contains(device: BTDevice) -> Bool {
        
        if let _ = devices.firstIndex(where: { $0.id == device.id }) {
            return true
        }
        return false
    }
    

    /// Does the device list contain the device represented by this peripheral
    func contains(peripheral: CBPeripheral) -> Bool {
        
        if let _ = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            return true
        }
        return false
    }

    
    mutating func setServiceConnectCallback(serviceCBUUID: CBUUID, callback: @escaping (Bool) -> Void) {
        
        // Set the callback function for when services connect / disconnect.
        
        serviceConnectCallback[serviceCBUUID] = callback
        
    }

    
    func getConnectionState(device: BTDevice) -> DeviceConnectionState? {

        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            return devices[index].connectionState
        }
        return nil
    }
    
    
    mutating func setConnectionState(device: BTDevice, connectionState: DeviceConnectionState) {
        
        let initialConnectedServices: Set<String> = connectedServices()
        
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index].connectionState = connectionState
            
        }
        
        let finalConnectedServices: Set<String> = connectedServices()
        
        let serviceConnects: Set<String>  = finalConnectedServices.subtracting(initialConnectedServices)
        let serviceDisconnects: Set<String>  = initialConnectedServices.subtracting(finalConnectedServices)

        for service in serviceConnects {
            logger.info("new service connect: \(service)")
            if (serviceConnectCallback[CBUUID(string: service)] != nil) {
                serviceConnectCallback[CBUUID(string: service)]!(true)
            }
        }

        for service in serviceDisconnects {
            logger.info("new service disconnect: \(service)")
            if (serviceConnectCallback[CBUUID(string: service)] != nil) {
                serviceConnectCallback[CBUUID(string: service)]!(false)
            }
        }

    }
    
    
    mutating func setConnectionState(peripheral: CBPeripheral, connectionState: DeviceConnectionState) {

        let initialConnectedServices: Set<String> = connectedServices()
        
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            devices[index].connectionState = connectionState
        }

        let finalConnectedServices: Set<String> = connectedServices()
        
        let serviceConnects: Set<String>  = finalConnectedServices.subtracting(initialConnectedServices)
        let serviceDisconnects: Set<String>  = initialConnectedServices.subtracting(finalConnectedServices)

        for service in serviceConnects {
            logger.info("new service connect: \(service)")
            if (serviceConnectCallback[CBUUID(string: service)] != nil) {
                serviceConnectCallback[CBUUID(string: service)]!(true)
            }
        }

        for service in serviceDisconnects {
            logger.info("new service disconnect: \(service)")
            if (serviceConnectCallback[CBUUID(string: service)] != nil) {
                serviceConnectCallback[CBUUID(string: service)]!(false)
            }
        }
    }
    
    
    func connectedServices() -> Set<String> {
        
        var services = Set<String>()
        
        for device in devices {
            if device.connectionState == .connected {
                services = services.union(device.services)
            }
        }
        return services
    }
    
    
    mutating func setDeviceInfo(device: BTDevice, key: String, value: String) {
        
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            if devices[index].setDeviceInfo(key: key, value: value) {
                // if device info has changed and list is persistent then update...
                if persistent {
                    cloudKitManager.CKForceUpdate(deviceRecord: devices[index].asCKRecord(), completionFunction: cloudKitManager.nilUpdateCompletion)
                    write()
                }
            }
            
        }
    }
    
    
    mutating func setDeviceInfo(peripheral: CBPeripheral, key: String, value: String) {
        
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            if devices[index].setDeviceInfo(key: key, value: value) {
                // if device info has changed and list is persistent then update...
                if persistent {
                    cloudKitManager.CKForceUpdate(deviceRecord: devices[index].asCKRecord(), completionFunction: cloudKitManager.nilUpdateCompletion)
                    write()
                }
            }
            
        }
    }

    
    mutating func reset() {
        devices = []
    }
    
    
    /// Add service to the device represented by the peripheral
    /// Write if persistent list
    mutating func addService(peripheral: CBPeripheral, service: String) {
    
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            if !devices[index].services.contains(service) {
                devices[index].services.append(service)
                if persistent {
                    cloudKitManager.CKForceUpdate(deviceRecord: devices[index].asCKRecord(), completionFunction: cloudKitManager.nilUpdateCompletion)
                    write()
                }
            }
        }

    }

    
    func servicesAsCBUUID(services: [String]) -> [CBUUID] {

        var serviceCBUUIDs: [CBUUID] = []
        for service in services {
            serviceCBUUIDs.append(CBUUID(string: service))
        }
        return serviceCBUUIDs

    }
    
    
    func services(device: BTDevice) -> [CBUUID] {
        
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            return servicesAsCBUUID(services: devices[index].services)
        }
        return []
    }
    
    
    func services(peripheral: CBPeripheral) -> [CBUUID] {
        
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            return servicesAsCBUUID(services: devices[index].services)
        }
        return []
    }
    

    mutating func read() {
        
        if !persistent {
            logger.error("Trying to read non-persistent device list!")
            return
        }
        guard let key = userDefaultsKey else {
            logger.error("userDefaultsKey not set for persistent list!")
            return
        }
        
        if let savedDevices = UserDefaults.standard.object(forKey: key) as? Data {
            logger.info("Read BTDevices")
            let decoder = JSONDecoder()
            if let loadedBTDevices = try? decoder.decode(type(of: devices), from: savedDevices) {
                logger.info("\(loadedBTDevices)")
                devices = loadedBTDevices
            }
        }
        
        fetchRecordBlock()
        
        
    }

    
    func write() {
        
        if !persistent {
            logger.error("Trying to write non-persistent device list!")
            return
        }
        guard let key = userDefaultsKey else {
            logger.error("userDefaultsKey not set for persistent list!")
            return
        }
        
        logger.info("Writing BT Devices")
        do {
            let data = try JSONEncoder().encode(devices)
            let jsonString = String(data: data, encoding: .utf8)
            logger.info("JSON : \(String(describing: jsonString))")
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            logger.error("Error enconding Devices")
        }
        
//        saveAndDeleteRecord(recordsToSave: devices.map({$0.asCKRecord()}), recordIDsToDelete: [])

    }

    
    func saveAndDeleteRecord(recordsToSave: [CKRecord],
                             recordIDsToDelete: [CKRecord.ID]) {

        logger.info("Saving records: \(recordsToSave.map( {$0.recordID} ))")
        logger.info("Deleting records: \(recordIDsToDelete)")

        let containerName: String = "iCloud.MurrayNet.Aleph"
        let container = CKContainer(identifier: containerName)
        let database = container.privateCloudDatabase

        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
        modifyRecordsOperation.qualityOfService = .utility
        modifyRecordsOperation.isAtomic = false
        
        // recordFetched is a function that gets called for each record retrieved
        modifyRecordsOperation.perRecordSaveBlock = { (recordID: CKRecord.ID, result: Result<CKRecord, any Error>) in
            switch result {
            case .success:
                logger.info("Saved \(recordID)")
                                
                break
                
            case .failure(let error):

                switch error {
                case CKError.accountTemporarilyUnavailable,
                    CKError.networkFailure,
                    CKError.networkUnavailable,
                    CKError.serviceUnavailable,
                    CKError.zoneBusy:
                    
                    logger.error("temporary error")
                    
                case CKError.serverRecordChanged:
                    // Record already exists- shouldn't happen, but!
                    logger.error("record already exists!")
                    
                default:
                    logger.error("permanent error")
                    
                }
                
                logger.error("Save failed with error : \(error.localizedDescription)")
                
                break
            }

        }
        
        
        modifyRecordsOperation.perRecordDeleteBlock = { (recordID: CKRecord.ID, result: Result<Void, any Error>) in
            switch result {
            case .success:
                logger.info("deleted and removed \(recordID)")
                
                break
                
            case .failure(let error):
                switch error {
                case CKError.unknownItem:
                    logger.error("item being deleted had not been saved")

                    return
                default:
                    logger.error("Deletion failed with error : \(error.localizedDescription)")
                    return
                }
            }
        }
            
        modifyRecordsOperation.modifyRecordsResultBlock = { (operationResult : Result<Void, any Error>) in
        
            switch operationResult {
            case .success:
                logger.info("Record modify completed")

                break
                
            case .failure(let error):
                logger.error( "modify failed \(String(describing: error))")

                break
            }

        }
        
        database.add(modifyRecordsOperation)

    }
    
    mutating func setDevices(deviceList: [BTDevice]) {
        devices = deviceList
    }
    

    private func fetchRecordBlock() {
        
        let pred = NSPredicate(value: true)
        let containerName: String = "iCloud.MurrayNet.Aleph"
        let container = CKContainer(identifier: containerName)
        let database = container.privateCloudDatabase
        var fetchedDevices: [BTDevice] = []

        let query = CKQuery(recordType: "BTDevices", predicate: pred)
        query.sortDescriptors = []

        let operation = CKQueryOperation(query: query)

        operation.desiredKeys = ["name", "services", "deviceInfo"]
        operation.resultsLimit = 200
        operation.qualityOfService = .utility

        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                if let fetchedDevice = self.deviceFromCKRecord(record: record) {
                    fetchedDevices.append(fetchedDevice)
                }
                break
                
            case .failure(let error):
                self.logger.error( "Fetch failed \(String(describing: error))")
                
                break
            }
        }
            
        operation.queryResultBlock = { result in


            switch result {
            case .success:

                self.logger.info("Device fetch complete")
//                devices = fetchedDevices
//                self.setDevices(deviceList: fetchedDevices)
                
                break
                    
            case .failure(let error):

                switch error {
                case CKError.accountTemporarilyUnavailable,
                    CKError.networkFailure,
                    CKError.networkUnavailable,
                    CKError.serviceUnavailable,
                    CKError.zoneBusy:
//                    CKError.notAuthenticated: //REMOVE!!
                    
                    self.logger.log("Temporary device fetch error")

                    
                default:
                    self.logger.error("permanent device fetch error")
                }
                self.logger.error( "Fetch failed \(String(describing: error))")
                break
            }

        }
        
        database.add(operation)

    }

  

    
    
}


class CloudKitManager: NSObject {

    var containerName: String
    var container: CKContainer
    var database: CKDatabase
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "CloudKitManager")
    
    override init() {
        containerName = "iCloud.MurrayNet.Aleph"
        container = CKContainer(identifier: containerName)
        database = container.privateCloudDatabase
        
    }

    
  
   
    func CKForceUpdate(deviceRecord: CKRecord, completionFunction: @escaping (CKRecord?) -> Void) {
        
        let containerName: String = "iCloud.MurrayNet.Aleph"
        let container = CKContainer(identifier: containerName)
        let database = container.privateCloudDatabase
        
        logger.log("updating \(deviceRecord.recordID)")
        
        database.modifyRecords(saving: [deviceRecord], deleting: [], savePolicy: .changedKeys) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let records):
                    print("Success Records : \(records)")
 
                    for recordResult in records.saveResults {
    
                        switch recordResult.value {
                        case .success(let record):
                            self.logger.log("Record updated \(record)")
                            completionFunction(record)
//                            _ = self.write()
                        case .failure(let error):
                            self.logger.error("Single Record update failed with error \(error.localizedDescription)")
                            completionFunction(nil)
                        }

                    }

                case .failure(let error):
                    self.logger.error("Batch Record update failed with error \(error.localizedDescription)")
                    // Delete temporary image file
                    completionFunction(nil)
                }
                

            }
        }
    }
    
    func nilUpdateCompletion(_: CKRecord?) -> Void {
        return
    }
    
    
}
