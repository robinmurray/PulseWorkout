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

let cyclePowerMeterCBUUID = CBUUID(string: "0x1818")

struct BTDevice: Identifiable {
    var identifier: UUID
    var name: String
    
    var id: UUID {
        identifier
    }
}

var knownBTDevices: [BTDevice] = [BTDevice(identifier: UUID(uuidString: "B1D7C9D0-12AC-FABC-FC29-B00EDE23F68E")!, name: "TICKR C703")]

class HRMViewController: NSObject, ObservableObject {

    @Published var discoveredDevices: [String] = []
    @Published var discoveredBTDevices: [BTDevice] = []
    @Published var bpm: Int = 0

    var profileData: ProfileData
    
    var heartRateLabel: String = ""
    var bodySensorLocationLabel: String = ""
    var centralManager: CBCentralManager!
    var heartRatePeripheral: CBPeripheral!
    
    var autoConnect: Bool = true
   
        
    init(profileData: ProfileData) {
        
        self.profileData = profileData
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }
    
    func resetDiscoveredDevices () {
        
        discoveredDevices = []
        
    }
    

    
  func onHeartRateReceived(_ heartRate: Int) {
      heartRateLabel = String(heartRate)
      print("BPM: \(heartRate)")
      profileData.setHeartRate(heartRate: Double(heartRate), hrSource: .bluetooth)
      
  }
    
    func cancelConnection() {
        self.centralManager.cancelPeripheralConnection(heartRatePeripheral)
    }
}

extension HRMViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {

        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
            profileData.BTHRMConnected = false
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
            profileData.BTHRMConnected = false
        case .poweredOn:
            print("central.state is .poweredOn")
            centralManager.scanForPeripherals(withServices: nil)
//            centralManager.scanForPeripherals(withServices: [heartRateServiceCBUUID])
            
        @unknown default:
            print("central.state is .default")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Found Peripheral of type...")
        print(peripheral)
        
        if peripheral.name != nil {
            if (!discoveredDevices.contains(peripheral.name ?? "")) {
                discoveredDevices.append(peripheral.name ?? "")
                discoveredBTDevices.append(BTDevice(identifier: peripheral.identifier, name: peripheral.name ?? ""))

            }
        }

        print("discoveredDevices = \(discoveredDevices)")
        print("discoveredBTDevices = \(discoveredBTDevices)")

        if knownBTDevices.map({ $0.name }).contains(peripheral.name) {
            print("found device \(peripheral) in known devices - attempt to connect!!")
            heartRatePeripheral = peripheral
            heartRatePeripheral.delegate = self
            
            centralManager.connect(heartRatePeripheral)
            
            // Stop scanning in this example - not going to do this later!!
            centralManager.stopScan()
        }
//        heartRatePeripheral = peripheral
//        centralManager.stopScan()
        
 //       centralManager.connect(heartRatePeripheral)

    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        profileData.BTHRMConnected = true
//        heartRatePeripheral.discoverServices(nil)
        heartRatePeripheral.discoverServices([heartRateServiceCBUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Connect failed with error \(String(describing: error))")
        
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected with error \(String(describing: error))")
        profileData.BTHRMConnected = false
        centralManager.scanForPeripherals(withServices: nil)
    }
}


extension HRMViewController: CBPeripheralDelegate {

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }

        for service in services {
            print(service)
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
          profileData.setHeartRate(heartRate: Double(bpm), hrSource: .bluetooth)

          
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


