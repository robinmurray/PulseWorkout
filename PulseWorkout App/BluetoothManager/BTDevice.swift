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

}

