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

// Heart Rate Monitor Bluetooth ID
let heartRateServiceCBUUID = CBUUID(string: "0x180D")
let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")
let bodySensorLocationCharacteristicCBUUID = CBUUID(string: "2A38")

let batteryServiceCBUUID = CBUUID(string: "0x180F")
let batteryLevelCharacteristicCBUUID = CBUUID(string: "0x2A19")

let cyclePowerMeterCBUUID = CBUUID(string: "0x1818")

let BTServices: [String: String] =
[heartRateServiceCBUUID.uuidString: "Heart Rate Monitor",
 batteryServiceCBUUID.uuidString: "Battery Level",
 cyclePowerMeterCBUUID.uuidString: "Power Meter"]

// use as BTServices[uuidString, default: "Unknown"]

struct BTDevice: Identifiable, Codable {
    var id: UUID
    var name: String
    var services: [String]

    func serviceDescriptions() -> [String] {
        
        var returnVal: [String] = []
        for service in services {
            returnVal.append(BTServices[service, default: service])
        }
        return returnVal
    }
}

var knownBTDevices: [BTDevice] = [BTDevice(id: UUID(uuidString: "B1D7C9D0-12AC-FABC-FC29-B00EDE23F68E")!, name: "TICKR C703", services: [])]

class BTDevicesController: NSObject, ObservableObject {

    @Published var discoveredDevices: [BTDevice] = []
    @Published var knownDevices: [BTDevice] = []
    @Published var connectedDevices: [BTDevice] = []
    var activePeripherals: [CBPeripheral] = []
    
    @Published var bpm: Int = 0

    var workoutManager: WorkoutManager

    var desiredConnectedDevices: Bool = true
    var heartRateLabel: String = ""
    var bodySensorLocationLabel: String = ""
    var centralManager: CBCentralManager!
    //var heartRatePeripheral: CBPeripheral!
    
    var autoConnect: Bool = true
   
        
    init(workoutManager: WorkoutManager) {
        
        self.workoutManager = workoutManager
        
        super.init()
        
        // Read list of known devices
        self.readKnownDevices()

        if knownDevices.count == 0 {
            knownDevices = knownBTDevices
            self.writeKnownDevices()
        }
        self.centralManager = CBCentralManager(delegate: self, queue: nil)        
    }
    
    func readKnownDevices() {
        print("Trying decode known BT Devices")
        
        if let savedDevices = UserDefaults.standard.object(forKey: "KnownBTDevices") as? Data {
            print("Read KnownBTDevices")
            let decoder = JSONDecoder()
            if let loadedBTDevices = try? decoder.decode(type(of: knownDevices), from: savedDevices) {
                print(loadedBTDevices)
                knownDevices = loadedBTDevices
            }
        }
    }

    func writeKnownDevices() {
        
        print("Writing known BT Devices")
        do {
            let data = try JSONEncoder().encode(knownDevices)
            let jsonString = String(data: data, encoding: .utf8)
            print("JSON : \(String(describing: jsonString))")
            UserDefaults.standard.set(data, forKey: "KnownBTDevices")
        } catch {
            print("Error enconding Known Devices")
        }

    }

    func disconnectDevice(btDevice: BTDevice) {
        
        for peripheral in activePeripherals {
            
            if peripheral.identifier == btDevice.id {
                
                if peripheral.state == CBPeripheralState.connected {
                    self.centralManager.cancelPeripheralConnection(peripheral)
                }
            }
        }
    }
    
    
    func forgetDevice(btDevice: BTDevice) {
        
        disconnectDevice(btDevice: btDevice)
        
        for (index, device) in knownDevices.enumerated() {
            if device.id == btDevice.id {
                knownDevices.remove(at: index)
                
                self.writeKnownDevices()
                return
            }
        }

    }

    func addServiceToKnownDevice(peripheral: CBPeripheral, service: String) {
    
        if let index = knownDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
            if !knownDevices[index].services.contains(service) {
                knownDevices[index].services.append(service)
                writeKnownDevices()
            }
        }

        if let index = connectedDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
            if !connectedDevices[index].services.contains(service) {
                connectedDevices[index].services.append(service)
            }
        }

        
    }
    func addKnownDevice(btDevice: BTDevice) {
        
        knownDevices.append(btDevice)
        self.writeKnownDevices()

    }
    
    func addActivePeripheral(peripheral: CBPeripheral) -> Int {

        // CHANGE THIS TO NOT REMOVE THEN ADD< BUT TO TEST FOR EXISTENCE AND THEN DO NOTHING
        removeActivePeripheral(peripheral: peripheral)
        
        activePeripherals.append(peripheral)
        
        print("Add active : \(activePeripherals)")
        // return index of new item
        return activePeripherals.count - 1
    }

    func removeActivePeripheral(peripheral: CBPeripheral) {

        print("removing ative peripheral \(peripheral)")
        if let index = activePeripherals.firstIndex(where: { $0.identifier == peripheral.identifier }) {
            activePeripherals.remove(at: index)
        }
    }

    func activePeripheralIndex(peripheral: CBPeripheral) -> Int? {

        print("TEST!!")
        print("activePeripherals : \(activePeripherals)")
        print("peripheral: \(peripheral)")
        return activePeripherals.firstIndex(where: { $0.identifier == peripheral.identifier })

    }

    func addConnectedDevice(peripheral: CBPeripheral) {

        // CHANGE THIS TO NOT REMOVE THEN ADD< BUT TO TEST FOR EXISTENCE AND THEN DO NOTHING

        removeConnectedDevice(peripheral: peripheral)
        
        connectedDevices.append(BTDevice(id: peripheral.identifier, name: peripheral.name ?? "Unknown", services:[]))
       
    }

    func removeConnectedDevice(peripheral: CBPeripheral) {

        if let index = connectedDevices.firstIndex(where: { $0.id == peripheral.identifier }) {
            connectedDevices.remove(at: index)
        }
        
    }

    func connectKnownDevices() {
        
        desiredConnectedDevices = true
        if self.centralManager.state == .poweredOn {
            self.centralManager.scanForPeripherals(withServices: nil)
        }
    }
    
    func disconnectKnownDevices() {
        
        print("Disconnecting known devices")
        print("Active peripherals : \(activePeripherals)")
        desiredConnectedDevices = false
        if self.centralManager.state == .poweredOn {
            self.centralManager.stopScan()
            
            for peripheral in activePeripherals {
                self.centralManager.cancelPeripheralConnection(peripheral)
                removeConnectedDevice(peripheral: peripheral)

            }
        }
    }
    
    func addDiscoveredDevice(peripheral: CBPeripheral) {
 
        if discoveredDevices.firstIndex(where: { $0.id == peripheral.identifier }) == nil {
            discoveredDevices.append(BTDevice(id: peripheral.identifier, name: peripheral.name ?? "", services: []))
        }
    }
    
    func resetDiscoveredDevices() {
        
        discoveredDevices = []
        
    }
    

    
  func onHeartRateReceived(_ heartRate: Int) {
      heartRateLabel = String(heartRate)
      print("BPM: \(heartRate)")
      workoutManager.setHeartRate(heartRate: Double(heartRate), hrSource: .bluetooth)
      
  }
    
}

extension BTDevicesController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {

        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
            workoutManager.BTHRMConnected = false
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
            workoutManager.BTHRMConnected = false
        case .poweredOn:
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: nil)
//            centralManager.scanForPeripherals(withServices: [heartRateServiceCBUUID])
            
        @unknown default:
            print("central.state is .default")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        addDiscoveredDevice(peripheral: peripheral)

        print("discoveredBTDevices = \(discoveredDevices)")

        if knownDevices.map({ $0.id }).contains(peripheral.identifier) {
            
            print("found device \(peripheral) in known devices - attempt to connect!!")

// ****            heartRatePeripheral = peripheral
// ****            heartRatePeripheral.delegate = self
            
            let index = addActivePeripheral(peripheral: peripheral)
            print("peripheral index = \(index)")
            activePeripherals[index].delegate = self
            centralManager.connect(activePeripherals[index])
// ****            centralManager.connect(heartRatePeripheral)

            // Stop scanning in this example - not going to do this later!!
            centralManager.stopScan()
        }

    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {

        print("Connected!")
        addConnectedDevice(peripheral: peripheral)
        print("connected devices : \(connectedDevices)")

        print("Services \(String(describing: peripheral.services))")
        
        workoutManager.BTHRMConnected = true
//        heartRatePeripheral.discoverServices(nil)
        let index = activePeripheralIndex(peripheral: peripheral)
        print(" connected index : \(index ?? -1)")
        if index != nil {
            activePeripherals[index!].discoverServices([heartRateServiceCBUUID])
        }
// ***        heartRatePeripheral.discoverServices([heartRateServiceCBUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Connect failed with error \(String(describing: error))")
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected with error \(String(describing: error))")
        
        print("peripheral : \(peripheral)")
        print("Active Peripherals : \(activePeripherals)")
        
        removeConnectedDevice(peripheral: peripheral)
        workoutManager.BTHRMConnected = false
        
//        work out if deliberate disconnect or error disconnect
        if desiredConnectedDevices {
            centralManager.scanForPeripherals(withServices: nil)
        }
    }
}


extension BTDevicesController: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }

        let index = activePeripheralIndex(peripheral: peripheral)
        print("service peripheral index : \(index ?? -1)")
        if index != nil {
            print("Add services to connected devices & known devices? in loop below!")
        }
        for service in services {
            print("Service for peripheral \(peripheral) : \(service)")
            print("UUID : \(service.uuid.uuidString)  description: \(service.uuid.description)")
            addServiceToKnownDevice(peripheral: peripheral, service: service.uuid.uuidString)
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
      switch characteristic.uuid {
          case bodySensorLocationCharacteristicCBUUID:
              let bodySensorLocation = bodyLocation(from: characteristic)
              print("bodySensorLocation \(bodySensorLocation)")
          
          case heartRateMeasurementCharacteristicCBUUID:
              bpm = heartRate(from: characteristic)
              print("bpm = \(bpm)")
              workoutManager.setHeartRate(heartRate: Double(bpm), hrSource: .bluetooth)

          case batteryLevelCharacteristicCBUUID:
              print( "battery level characteristic \(characteristic) for peripheral \(peripheral)")

          default:
              print("Unhandled Characteristic UUID: \(characteristic.uuid)")
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
}


