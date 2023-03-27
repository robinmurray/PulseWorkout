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
let serialNumberStringCharacteristicCBUUID = CBUUID(string: "0x2A25")
let firmwareRevisionStringCharacteristicCBUUID = CBUUID(string: "0x2A26")
let hardwareRevisionStringCharacteristicCBUUID = CBUUID(string: "0x2A27")
let softwareRevisionStringCharacteristicCBUUID = CBUUID(string: "0x2A28")
let manufacturerNameStringCharacteristicCBUUID = CBUUID(string: "0x2A29")

let heartRateServiceCBUUID = CBUUID(string: "0x180D")
let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "0x2A37")
let bodySensorLocationCharacteristicCBUUID = CBUUID(string: "0x2A38")

let batteryServiceCBUUID = CBUUID(string: "0x180F")
let batteryLevelCharacteristicCBUUID = CBUUID(string: "0x2A19")

let cyclePowerMeterCBUUID = CBUUID(string: "0x1818")
let cyclingPowerFeatureCBUUID = CBUUID(string: "0x2A65")
let sensorLocationCBUUID = CBUUID(string: "0x2A5D")
let cyclingPowerMeasurementCBUUID = CBUUID(string: "0x2A63")

let cycleSpeedCadenceCBUUID = CBUUID(string: "0x1816")

// use as BTServices[uuidString, default: "Unknown"]
let BTServices: [String: String] =
[currentTimeServiceCBUUID.uuidString: "Current Time",
 deviceInfoServiceCBUUID.uuidString: "Device Info",
 heartRateServiceCBUUID.uuidString: "Heart Rate Monitor",
 batteryServiceCBUUID.uuidString: "Battery Level",
 cyclePowerMeterCBUUID.uuidString: "Power Meter"]


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
        
        // Set the callback function for when services connect / disconnect.
        
        serviceConnectCallback[serviceCBUUID] = callback
        knownDevices.setServiceConnectCallback(serviceCBUUID: serviceCBUUID, callback: callback)
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
//            serviceConnectCallback[heartRateServiceCBUUID]!(false)
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
            // TO CHANGE!!
//            serviceConnectCallback[heartRateServiceCBUUID]!(false)
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
        if centralManager.state == .poweredOn {
            discoveredDevices.reset()
            self.centralManager.stopScan()
            discoveringDevices = true
            scanForDevices()
        }
    }
    
    func stopDiscoverDevices() {
        if centralManager.state == .poweredOn {
            discoveringDevices = false
            if connectableDevices.empty() {
                centralManager.stopScan()
            }
        }
    }
    
    func connectIfKnown(peripheral: CBPeripheral) {
        
        if connectableDevices.contains(peripheral: peripheral) {
            print("found device \(peripheral) in known devices - attempt to connect!!")

            knownDevices.setConnectionState(peripheral: peripheral, connectionState: .connecting)
            discoveredDevices.setConnectionState(peripheral: peripheral, connectionState: .connecting)
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
            if !knownDevices.contains(peripheral: peripheral) {
                discoveredDevices.add(peripheral: peripheral)
                print("discoveredBTDevices = \(discoveredDevices)")
            }
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
        
        knownDevices.setConnectionState(peripheral: peripheral, connectionState: .connected)
        // if device is in discoveringDevices - set to connected... or remove???
        discoveredDevices.setConnectionState(peripheral: peripheral, connectionState: .connected)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Connect failed with error \(String(describing: error))")
        
        knownDevices.setConnectionState(peripheral: peripheral, connectionState: .disconnected)

    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected with error \(String(describing: error))")
        
        knownDevices.setConnectionState(peripheral: peripheral, connectionState: .disconnected)

        // Add back to connectable devices
        if knownDevices.contains(peripheral: peripheral) {
            connectableDevices.add(peripheral: peripheral)
        }

        scanForDevices()

    }
}


extension BTDevicesController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }

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
 
        case firmwareRevisionStringCharacteristicCBUUID:
            print("firmware revision characteristic \(characteristic) for peripheral \(peripheral)")
            knownDevices.setDeviceInfo(peripheral: peripheral, key: "Firmware Revision", value: stringCharacteristic(from: characteristic))
            knownDevices.write(key: knownDeviceKey)
            
        case hardwareRevisionStringCharacteristicCBUUID:
            print("hardware revision characteristic \(characteristic) for peripheral \(peripheral)")
            knownDevices.setDeviceInfo(peripheral: peripheral, key: "Hardware Revision", value: stringCharacteristic(from: characteristic))
            knownDevices.write(key: knownDeviceKey)
            
        case softwareRevisionStringCharacteristicCBUUID:
            print("software revision characteristic \(characteristic) for peripheral \(peripheral)")
            knownDevices.setDeviceInfo(peripheral: peripheral, key: "Software Revision", value: stringCharacteristic(from: characteristic))
            knownDevices.write(key: knownDeviceKey)
            
        case manufacturerNameStringCharacteristicCBUUID:
            print("manufacturer name characteristic \(characteristic) for peripheral \(peripheral)")
            knownDevices.setDeviceInfo(peripheral: peripheral, key: "Manufacturer", value: stringCharacteristic(from: characteristic))
            knownDevices.write(key: knownDeviceKey)

        case cyclingPowerFeatureCBUUID:
            print("cyclingPowerFeatureCBUUID characteristic \(characteristic) for peripheral \(peripheral)")
        case sensorLocationCBUUID:
            print("sensorLocationCBUUID characteristic \(characteristic) for peripheral \(peripheral)")
        case cyclingPowerMeasurementCBUUID:
            print("cyclingPowerMeasurementCBUUID characteristic \(characteristic) for peripheral \(peripheral)")
            
            // return value is a dict [String: Any]
            returnValue = cyclingPower(from: characteristic)
//            let instantaneousPower = returnValue as [String: Any]["instantaneousPower"]
//            print("Instantaneous Power \(instantaneousPower ?? -1)")
            
        default:
            print("Unhandled Characteristic: \(characteristic) for peripheral \(peripheral)")
            
        }
        
        if (characteristicCallback[characteristic.uuid] != nil) && (returnValue != nil) {
            characteristicCallback[characteristic.uuid]!(returnValue!)
        }
    }
    
    private func stringCharacteristic(from characteristic: CBCharacteristic) -> String {

        guard let characteristicData = characteristic.value else { return "" }
        
        return String(data: characteristicData, encoding: .utf8) ?? ""

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

    private func cyclingPower(from characteristic: CBCharacteristic) -> [String:Any] {

        struct FlagRule {
            var flag: String
            var byte: Int
            var bitmap: UInt8
        }
        
        let flagMap: [FlagRule] = [FlagRule(flag: "Pedal Power Balance Present", byte: 0, bitmap: 0x01),
                                   FlagRule(flag: "Pedal Power Balance Reference", byte: 0, bitmap: 0x02),
                                   FlagRule(flag: "Accumulated Torque Present", byte: 0, bitmap: 0x04),
                                   FlagRule(flag: "Accumulated Torque Source", byte: 0, bitmap: 0x08),
                                   FlagRule(flag: "Wheel Revolution Data Present", byte: 0, bitmap: 0x10),
                                   FlagRule(flag: "Crank Revolution Data Present", byte: 0, bitmap: 0x20),
                                   FlagRule(flag: "Extreme Force Magnitudes Present", byte: 0, bitmap: 0x40),
                                   FlagRule(flag: "Extreme Torque Magnitudes Present", byte: 0, bitmap: 0x80),
                                   FlagRule(flag: "Extreme Angles Present", byte: 1, bitmap: 0x01),
                                   FlagRule(flag: "Top Dead Spot Angle Present", byte: 1, bitmap: 0x02),
                                   FlagRule(flag: "Bottom Dead Spot Angle Present", byte: 1, bitmap: 0x04),
                                   FlagRule(flag: "Accumulated Energy Present", byte: 1, bitmap: 0x08),
                                   FlagRule(flag: "Offset Compensation Indicator", byte: 1, bitmap: 0x10)]
        
        var flags: [String: Bool] = [:]
        var byteIndex: Int = 0
        var powerMeterValues: [String: Any] = [:]
        
        guard let characteristicData = characteristic.value else { return [:] }
        let byteArray = [UInt8](characteristicData)
        
        for flagRule in flagMap {
            flags[flagRule.flag] = (byteArray[flagRule.byte] & flagRule.bitmap != 0)
        }

        print("Cycling Power meter flags : \(flags)")
        
        // Unit is in watts with a resolution of 1. - Mandatory
        byteIndex = 2
        powerMeterValues["instantaneousPower"] = Int(byteArray[byteIndex]) + (Int(byteArray[byteIndex+1]) * 256)
        byteIndex = 4
        
        // Unit is in percentage with a resolution of 1/2. - Optional
        if flags["Pedal Power Balance Present"] ?? false {
            powerMeterValues["pedalPowerBalance"] = Int(byteArray[byteIndex])
            byteIndex += 1
        }

        // Unit is in newton metres with a resolution of 1/32.
        if flags["Accumulated Torque Present"] ?? false {
            powerMeterValues["accumulatedTorque"] = Int(byteArray[byteIndex]) + (Int(byteArray[byteIndex+1]) * 256)
            byteIndex += 2
        }

        if flags["Wheel Revolution Data Present"] ?? false {
            powerMeterValues["cumulativeWheelRevolutions"] = Int32(byteArray[byteIndex]) + (Int32(byteArray[byteIndex+1]) * 256)  + (Int32(byteArray[byteIndex+2]) * 256 * 256) + (Int32(byteArray[byteIndex+3]) * 256 * 256 * 256)
            byteIndex += 4
            // Unit is in seconds with a resolution of 1/2048.
            powerMeterValues["lastWheelEventTime"] = Int(byteArray[byteIndex]) + (Int(byteArray[byteIndex+1]) * 256)
            byteIndex += 2
        }

        if flags["Crank Revolution Data Present"] ?? false {
            powerMeterValues["cumulativeCrankRevolutions"] = Int(byteArray[byteIndex]) + (Int(byteArray[byteIndex+1]) * 256)
            byteIndex += 2
            
            // Unit is in seconds with a resolution of 1/1024.
            powerMeterValues["lastCrankEventTime"] = Int(byteArray[byteIndex]) + (Int(byteArray[byteIndex+1]) * 256)
            byteIndex += 2
        }

        if flags["Extreme Force Magnitudes Present"] ?? false {
            // Unit is in newtons with a resolution of 1.
            powerMeterValues["maximumForceMagnitudes"] = Int(byteArray[byteIndex]) + (Int(byteArray[byteIndex+1]) * 256)
            byteIndex += 2
            
            // Unit is in newtons with a resolution of 1.
            powerMeterValues["minimumForceMagnitude"] = Int(byteArray[byteIndex]) + (Int(byteArray[byteIndex+1]) * 256)
            byteIndex += 2
        }

        if flags["Extreme Torque Magnitudes Present"] ?? false {
            // Unit is in newton metres with a resolution of 1/32.
            powerMeterValues["maximumTorqueMagnitude"] = Int(byteArray[byteIndex]) + (Int(byteArray[byteIndex+1]) * 256)
            byteIndex += 2
            
            // Unit is in newton metres with a resolution of 1/32.
            powerMeterValues["minimumTorqueMagnitude"] = Int(byteArray[byteIndex]) + (Int(byteArray[byteIndex+1]) * 256)
            byteIndex += 2
        }

        if flags["Extreme Angles Present"] ?? false {
            // Unit is in degrees with a resolution of 1
            // NOTE - combined in single value!!
            powerMeterValues["extremeAngles"] = Int(byteArray[byteIndex]) + (Int(byteArray[byteIndex+1]) * 256) + (Int(byteArray[byteIndex+2]) * 256 * 256)
            byteIndex += 3
            
        }

        if flags["Top Dead Spot Angle Present"] ?? false {
            // Unit is in degrees with a resolution of 1.
            powerMeterValues["topDeadSpotAngle"] = Int(byteArray[byteIndex]) + (Int(byteArray[byteIndex+1]) * 256)
            byteIndex += 2

        }

        if flags["Bottom Dead Spot Angle Present"] ?? false {
            // Unit is in degrees with a resolution of 1.
            powerMeterValues["bottomDeadSpotAngle"] = Int(byteArray[byteIndex]) + (Int(byteArray[byteIndex+1]) * 256)
            byteIndex += 2

        }

        if flags["Accumulated Energy Present"] ?? false {
            // Unit is in kilojoules with a resolution of 1.
            powerMeterValues["accumulatedEnergy"] = Int(byteArray[byteIndex]) + (Int(byteArray[byteIndex+1]) * 256)
            byteIndex += 2

        }

        
        print("powerMeterValues: \(powerMeterValues)")
        
        return powerMeterValues
//        return powerMeterValues["instantaneousPower"] as! Int

    }
}


