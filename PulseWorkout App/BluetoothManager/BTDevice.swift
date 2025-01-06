//
//  BTDevice.swift
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
