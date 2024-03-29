//
//  BTPeripheralManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 10/09/2023.
//

import Foundation
import CoreBluetooth
import os



class BTPeripheralManager: NSObject, ObservableObject {

    private var service: CBUUID!
    private let value = "AD34E"
    
    private var peripheralManager : CBPeripheralManager!
    
    override init() {
        
        super.init()
        
        peripheralManager = CBPeripheralManager()
        peripheralManager.delegate = self
    }
}



extension BTPeripheralManager: CBPeripheralManagerDelegate {

    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                            category: "BTPeripheralManager")

        switch peripheral.state {
            case .unknown:
                logger.log("Bluetooth Peripheral Device is UNKNOWN")
            case .unsupported:
                logger.log("Bluetooth Peripheral Device is UNSUPPORTED")
            case .unauthorized:
                logger.log("Bluetooth Peripheral Device is UNAUTHORIZED")
            case .resetting:
                logger.log("Bluetooth Peripheral Device is RESETTING")
            case .poweredOff:
                logger.log("Bluetooth Peripheral Device is POWERED OFF")
            case .poweredOn:
                logger.log("Bluetooth Peripheral Device is POWERED ON")
    //            addServices()
            @unknown default:
                logger.log("Bluetooth Peripheral Device Unknown State")
        }
    }
    
/*
    func addServices() {
        let valueData = value.data(using: .utf8)

         // 1. Create instance of CBMutableCharcateristic
        var myChar1 = CBCharacteristic.
        
//        let myChar1 = CBMutableCharacteristic(type: CBUUID(nsuuid: UUID()), properties: [.notify, .write, .read], value: nil, permissions: [.readable, .writeable])
        let myChar2 = CBMutableCharacteristic(type: CBUUID(nsuuid: UUID()), properties: [.read], value: valueData, permissions: [.readable])
        
        // 2. Create instance of CBMutableService
        service = CBUUID(nsuuid: UUID())
        
        let myService = CBMutableService(type: service, primary: true)
        // 3. Add characteristics to the service
        
        myService.characteristics = [myChar1, myChar2]
        // 4. Add service to peripheralManager
        peripheralManager.add(myService)
        // 5. Start advertising
        startAdvertising()
    }
 */
}
