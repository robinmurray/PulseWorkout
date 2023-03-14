//
//  BluetoothManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 26/01/2023.
//

import Foundation
import CoreBluetooth
import WatchKit
import UIKit

// User Defaults Key
let knownDeviceKey: String = "KnownBTDevices"

// Heart Rate Monitor Bluetooth ID
let currentTimeServiceCBUUID = CBUUID(string: "0x1805")
let deviceInfoServiceCBUUID = CBUUID(string: "0x180A")
let heartRateServiceCBUUID = CBUUID(string: "0x180D")
let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")
let bodySensorLocationCharacteristicCBUUID = CBUUID(string: "2A38")

let batteryServiceCBUUID = CBUUID(string: "0x180F")
let batteryLevelCharacteristicCBUUID = CBUUID(string: "0x2A19")

let cyclePowerMeterCBUUID = CBUUID(string: "0x1818")

let BTServices: [String: String] =
[currentTimeServiceCBUUID.uuidString: "Current Time",
 deviceInfoServiceCBUUID.uuidString: "Device Info",
 heartRateServiceCBUUID.uuidString: "Heart Rate Monitor",
 batteryServiceCBUUID.uuidString: "Battery Level",
 cyclePowerMeterCBUUID.uuidString: "Power Meter"]

// use as BTServices[uuidString, default: "Unknown"]

let defaultBTDevices: [BTDevice] = [BTDevice(id: UUID(uuidString: "B1D7C9D0-12AC-FABC-FC29-B00EDE23F68E")!, name: "TICKR C703", services: [])]


enum DeviceConnectionState {
    case disconnected, connecting, connected
}


struct BTDevice: Identifiable, Codable {
    var id: UUID
    var name: String
    var services: [String]
    var connectionState: DeviceConnectionState?
    
    // set CodingKeys to exclude connectionState from coding/decoding
    private enum CodingKeys: String, CodingKey {
        case id, name, services
    }

    func serviceDescriptions() -> [String] {
        
        var returnVal: [String] = []
        for service in services {
            returnVal.append(BTServices[service, default: service])
        }
        return returnVal
    }
    
    func connected(bluetoothManager: BTDevicesController) -> Bool {
        
        for peripheral in bluetoothManager.activePeripherals {
            
            if peripheral.identifier == id {
                
                return peripheral.state == CBPeripheralState.connected

            }
        }
        return false
    }
}

struct DeviceList {
    var devices: [BTDevice]
    
    func deviceFromPeripheral(peripheral: CBPeripheral) -> BTDevice {
        
        return BTDevice(id: peripheral.identifier, name: peripheral.name ?? "Unknown", services: [])
    }
    
    func empty() -> Bool {
        return devices.count == 0
    }
    
    mutating func setDefault() {
        devices = defaultBTDevices
    }
    mutating func add(device: BTDevice) {
        
        if let _ = devices.firstIndex(where: { $0.id == device.id }) {
            return
        }
        devices.append(device)
    }
    
    mutating func add(peripheral: CBPeripheral) {
        
        if let _ = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            return
        }
        devices.append(deviceFromPeripheral(peripheral: peripheral))
    }
    
    mutating func remove(device: BTDevice) {
        
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices.remove(at: index)
        }
    }
    
    mutating func remove(peripheral: CBPeripheral) {
        
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            devices.remove(at: index)
        }
    }
    
    func contains(device: BTDevice) -> Bool {
        
        if let _ = devices.firstIndex(where: { $0.id == device.id }) {
            return true
        }
        return false
    }
    
    func contains(peripheral: CBPeripheral) -> Bool {
        
        if let _ = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            return true
        }
        return false
    }
    
    mutating func setConnectionState(device: BTDevice, connectionState: DeviceConnectionState) {
        
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            devices[index].connectionState = connectionState
            
        }
    }
    
    mutating func setConnectionState(peripheral: CBPeripheral, connectionState: DeviceConnectionState) {
        
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            devices[index].connectionState = connectionState
            
        }
        
    }
    
    mutating func reset() {
        devices = []
    }
    
    mutating func addService(peripheral: CBPeripheral, service: String) {
    
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            if !devices[index].services.contains(service) {
                devices[index].services.append(service)
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
    

    mutating func read(key: String) {
        print("Trying decode BT Devices")
        
        if let savedDevices = UserDefaults.standard.object(forKey: key) as? Data {
            print("Read BTDevices")
            let decoder = JSONDecoder()
            if let loadedBTDevices = try? decoder.decode(type(of: devices), from: savedDevices) {
                print(loadedBTDevices)
                devices = loadedBTDevices
            }
        }
    }

    func write(key: String) {
        
        print("Writing BT Devices")
        do {
            let data = try JSONEncoder().encode(devices)
            let jsonString = String(data: data, encoding: .utf8)
            print("JSON : \(String(describing: jsonString))")
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            print("Error enconding Devices")
        }

    }

}


class BTDevicesController: NSObject, ObservableObject {

    @Published var knownDevices: DeviceList = DeviceList(devices: [])
    @Published var discoveredDevices: DeviceList = DeviceList(devices: [])
    @Published var connectableDevices: DeviceList = DeviceList(devices: [])
    
    var activePeripherals: [CBPeripheral] = []
    
    var discoveringDevices: Bool = false
    
    @Published var bpm: Int = 0
   
    var bodySensorLocationLabel: String = ""
    
    var centralManager: CBCentralManager!
    var requestedServices: [CBUUID]?
    
    var characteristicCallback: [CBUUID: (Any) -> Void] = [:]
    var serviceConnectCallback: [CBUUID: (Bool) -> Void] = [:]
    var batteryLevelCallback: [CBUUID: (Int) -> Void] = [:]

    init(requestedServices: [CBUUID]?) {
        
        self.requestedServices = requestedServices
        
        super.init()
        
        // Read list of known devices
        knownDevices.read(key: knownDeviceKey)

        if knownDevices.empty() {
            knownDevices.setDefault()
            knownDevices.write(key: knownDeviceKey)
        }
        
        // connectableDevices is list of devices to connect to if seen
        connectableDevices.devices = knownDevices.devices
        
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func setCharacteristicCallback(characteristicCBUUID: CBUUID, callback: @escaping (Any) -> Void) {
        
        // Set the callback function for when the characteristic value is read.
        
        characteristicCallback[characteristicCBUUID] = callback
        
    }

    func setServiceConnectCallback(serviceCBUUID: CBUUID, callback: @escaping (Bool) -> Void) {
        
        // Set the callback function for when serivces connect / disconnect.
        
        serviceConnectCallback[serviceCBUUID] = callback
        
    }

    func setBatteryLevelCallback(serviceCBUUID: CBUUID, callback: @escaping (Int) -> Void) {
        
        // Set the callback function for when battery level relevant to a service is read.
        
        batteryLevelCallback[serviceCBUUID] = callback
        
    }

    func disconnectDevice(device: BTDevice) {
        
        for peripheral in activePeripherals {
            
            if peripheral.identifier == device.id {
                
                if peripheral.state == CBPeripheralState.connected {
                    self.centralManager.cancelPeripheralConnection(peripheral)
                }
            }
        }
    }
    
    func forgetDevice(device: BTDevice) {
        
        disconnectDevice(device: device)
        connectableDevices.remove(device: device)
        discoveredDevices.add(device: device)
        knownDevices.remove(device: device)
        knownDevices.write(key: knownDeviceKey)
    }
    
    func addActivePeripheral(peripheral: CBPeripheral) -> Int {

        if let index = activePeripheralIndex(peripheral: peripheral) {
            return index
        }
        
        activePeripherals.append(peripheral)
        
        // return index of new item
        return activePeripherals.count - 1
    }

    func removeActivePeripheral(peripheral: CBPeripheral) {

        print("removing active peripheral \(peripheral)")
        if let index = activePeripherals.firstIndex(where: { $0.identifier == peripheral.identifier }) {
            activePeripherals.remove(at: index)
        }
    }

    func activePeripheralIndex(peripheral: CBPeripheral) -> Int? {

        return activePeripherals.firstIndex(where: { $0.identifier == peripheral.identifier })

    }

    func connectDevices() {
        
        if self.centralManager.state == .poweredOn {
            self.centralManager.scanForPeripherals(withServices: requestedServices)
        }
    }
    
    func disconnectKnownDevices() {
        
        print("Disconnecting known devices")
        print("Active peripherals : \(activePeripherals)")

        if self.centralManager.state == .poweredOn {
            self.centralManager.stopScan()
            
            for peripheral in activePeripherals {
                self.centralManager.cancelPeripheralConnection(peripheral)

                if knownDevices.contains(peripheral: peripheral) {
                    connectableDevices.add(peripheral: peripheral)
                }
            }
        }
    }
    
}

extension BTDevicesController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {

        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
            // TO CHANGE!!
            serviceConnectCallback[heartRateServiceCBUUID]!(false)
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
            // TO CHANGE!!
            serviceConnectCallback[heartRateServiceCBUUID]!(false)
        case .poweredOn:
            print("central.state is .poweredOn")
            scanForDevices()
            
        @unknown default:
            print("central.state is .default")
        }
    }
    
    func scanForDevices() {
        if self.centralManager.state == .poweredOn {
            if !connectableDevices.empty() || discoveringDevices == true {
                centralManager.scanForPeripherals(withServices: requestedServices)
            }
        }
    }
    
    func discoverDevices() {
        discoveredDevices.reset()
        discoveringDevices = true
        scanForDevices()
    }
    
    func stopDiscoverDevices() {
        discoveringDevices = false
        if connectableDevices.empty() {
            centralManager.stopScan()
        }
    }
    func connectIfKnown(peripheral: CBPeripheral) {
        
        if connectableDevices.contains(peripheral: peripheral) {
            print("found device \(peripheral) in known devices - attempt to connect!!")

            let index = addActivePeripheral(peripheral: peripheral)
            print("peripheral index = \(index)")
            activePeripherals[index].delegate = self
            centralManager.connect(activePeripherals[index])
        }

    }

    func connectDevice(device: BTDevice) {
        print("attempting to connect device \(device)")
        print("Active peripherals \(activePeripherals)")
        
        connectableDevices.add(device: device)

        print("Connectable devices \(connectableDevices)")
        if let index = activePeripherals.firstIndex(where: { $0.identifier == device.id }) {
            activePeripherals[index].delegate = self
            print("connecting...")
            centralManager.connect(activePeripherals[index])
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if connectableDevices.contains(peripheral: peripheral) {
            connectIfKnown(peripheral: peripheral)
        }
        else {
            discoveredDevices.add(peripheral: peripheral)
            print("discoveredBTDevices = \(discoveredDevices)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {

        print("Connected!")
        knownDevices.add(peripheral: peripheral)
        knownDevices.write(key: knownDeviceKey)

        // Remove from Connectable Device list
        connectableDevices.remove(peripheral: peripheral)
        
        if connectableDevices.empty() && !discoveringDevices {
            centralManager.stopScan()
        }

        var services = requestedServices
        if services != nil {
            services! += [batteryServiceCBUUID]
        }
        let index = activePeripheralIndex(peripheral: peripheral)
        print(" connected index : \(index ?? -1)")
                
        if index != nil {
            activePeripherals[index!].discoverServices(services)
        }
        
        // TO DO : CHANGE BELOW!!
        // TO CHANGE!!
        serviceConnectCallback[heartRateServiceCBUUID]!(true)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Connect failed with error \(String(describing: error))")
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected with error \(String(describing: error))")
        
        print("peripheral : \(peripheral)")
        print("Active Peripherals : \(activePeripherals)")
        
        // Add back to connectable devices
        if knownDevices.contains(peripheral: peripheral) {
            connectableDevices.add(peripheral: peripheral)
        }

        scanForDevices()
        
        // TO DO: STUFF BELOW HERE TO BE CHANGED!!
        // TO CHANGE!!
        serviceConnectCallback[heartRateServiceCBUUID]!(false)
    }
}


extension BTDevicesController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
/*
        let index = activePeripheralIndex(peripheral: peripheral)
        print("service peripheral index : \(index ?? -1)")
        if index != nil {
            print("Add services to connected devices & known devices? in loop below!")
        }
 */
        
        // make sure all services registered before discovering characteristics
        for service in services {
            print("Service for peripheral \(peripheral) : \(service)")
            print("UUID : \(service.uuid.uuidString)  description: \(service.uuid.description)")
            knownDevices.addService(peripheral: peripheral, service: service.uuid.uuidString)
            peripheral.discoverCharacteristics(nil, for: service)
        }
        knownDevices.write(key: knownDeviceKey)

        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }

    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            print(characteristic)
            if characteristic.properties.contains(.read) {
                print("\(characteristic.uuid): properties contains .read")
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                print("\(characteristic.uuid): properties contains .notify")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        
        var returnValue: Any?
        
        switch characteristic.uuid {
        case bodySensorLocationCharacteristicCBUUID:
            let bodySensorLocation = bodyLocation(from: characteristic)
            print("bodySensorLocation \(bodySensorLocation)")
            // returnValue as String
            returnValue = bodySensorLocation
            
        case heartRateMeasurementCharacteristicCBUUID:
            bpm = heartRate(from: characteristic)
            print("bpm = \(bpm)")
            // returnValue as Double
            returnValue = Double(bpm)
            
        case batteryLevelCharacteristicCBUUID:
            print("battery level characteristic \(characteristic) for peripheral \(peripheral)")
            let batteryLevel = batteryLevel(from: characteristic)
            print("battery level = \(batteryLevel)")
            
            for service in knownDevices.services(peripheral: peripheral) {
                if (batteryLevelCallback[service] != nil) {
                    batteryLevelCallback[service]!(batteryLevel)
                }

            }
            // batteryLevel is Int
            returnValue = batteryLevel
            
        default:
            print("Unhandled Characteristic UUID: \(characteristic.uuid) for peripheral \(peripheral)")
        }
        
        if (characteristicCallback[characteristic.uuid] != nil) && (returnValue != nil) {
            characteristicCallback[characteristic.uuid]!(returnValue!)
        }
    }
    
    private func bodyLocation(from characteristic: CBCharacteristic) -> String {
        guard let characteristicData = characteristic.value,
              let byte = characteristicData.first else { return "Error" }
        
        switch byte {
        case 0: return "Other"
        case 1: return "Chest"
        case 2: return "Wrist"
        case 3: return "Finger"
        case 4: return "Hand"
        case 5: return "Ear Lobe"
        case 6: return "Foot"
        default:
            return "Reserved for future use"
        }
    }
    
    private func heartRate(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        
        let firstBitValue = byteArray[0] & 0x01
        if firstBitValue == 0 {
            // Heart Rate Value Format is in the 2nd byte
            return Int(byteArray[1])
        } else {
            // Heart Rate Value Format is in the 2nd and 3rd bytes
            return (Int(byteArray[1]) << 8) + Int(byteArray[2])
        }
    }
    
    private func batteryLevel(from characteristic: CBCharacteristic) -> Int {
        
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        let batteryLevel = Int(byteArray[0])

        return batteryLevel
    }

}


