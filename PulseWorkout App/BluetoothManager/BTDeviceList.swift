//
//  BTDeviceList.swift
//  PulseWorkout
//
//  Created by Robin Murray on 06/01/2025.
//

import Foundation
import CoreBluetooth
import CloudKit
import os

class BTDeviceList: NSObject, ObservableObject {
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "BTDeviceList")

    override var description: String {
        return "Device List description <HERE>"
    }
    
    @Published var devices: [BTDevice]
    
    /// Temporary device list for fetching from CloudKit
    var fetchedDevices: [BTDevice] = []
    
    /// Whether the list is persistent and stored to Cloudkit & UserDefaults
    /// Set to true for knownDevices
    var persistent: Bool
    
    /// Key for storing persistent list in user defaults
    var userDefaultsKey: String?
    
    var serviceConnectCallback: [CBUUID: (Bool) -> Void] = [:]

    
    /// Initialise a non-persistent list
    override init() {
        devices = []
        persistent = false
    }
    
    /// Initialise a persistent list - stored to cloudkit and userDefaults
    init(persistent: Bool, userDefaultsKey: String?) {
        self.devices = []
        self.persistent = persistent
        self.userDefaultsKey = userDefaultsKey
    }


    func deviceFromPeripheral(peripheral: CBPeripheral) -> BTDevice {
        
        return BTDevice(id: peripheral.identifier, name: peripheral.name ?? "Unknown", services: [], deviceInfo: [:])
    }
    
    
    
    func empty() -> Bool {
        return devices.count == 0
    }
    
    
    func setDefault() {
        devices = defaultBTDevices
        if persistent { write() }

    }
    
    
    /// Add device to this device list
    /// If device list is persistent, write to cloudkit and UserDefaults
    func add(device: BTDevice) {
        
        if let _ = devices.firstIndex(where: { $0.id == device.id }) {
            return
        }
        devices.append(device)
        
        if persistent { write() }
        
    }
    
    
    /// Add device represented by the BT peripheral to this device list
    /// If device list is persistent, write to cloudkit and UserDefaults
    func add(peripheral: CBPeripheral) {
        
        if let _ = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            return
        }
        add(device: deviceFromPeripheral(peripheral: peripheral))

    }
    
    
    /// Remove device from this device list
    /// If device list is persistent, write to cloudkit and UserDefaults
    func remove(device: BTDevice) {
        
        if let index = devices.firstIndex(where: { $0.id == device.id }) {

            devices.remove(at: index)
            
            if persistent { write() }
        }
    }
    
    
    /// Remove device represented by this BT Peripheral from this device list
    /// If device list is persistent, write to cloudkit and UserDefaults
    func remove(peripheral: CBPeripheral) {
        
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {

            devices.remove(at: index)
            
            if persistent { write() }
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

    
    func setServiceConnectCallback(serviceCBUUID: CBUUID, callback: @escaping (Bool) -> Void) {
        
        // Set the callback function for when services connect / disconnect.
        
        serviceConnectCallback[serviceCBUUID] = callback
        
    }

    
    func getConnectionState(device: BTDevice) -> DeviceConnectionState? {

        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            return devices[index].connectionState
        }
        return nil
    }
    
    
    func setConnectionState(device: BTDevice, connectionState: DeviceConnectionState) {
        
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
    
    
    func setConnectionState(peripheral: CBPeripheral, connectionState: DeviceConnectionState) {

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
    
    
    func setDeviceInfo(device: BTDevice, key: String, value: String) {
        
        if let index = devices.firstIndex(where: { $0.id == device.id }) {
            if devices[index].setDeviceInfo(key: key, value: value) {
                // if device info has changed and list is persistent then update...
                if persistent { write() }
            }
            
        }
    }
    
    
    func setDeviceInfo(peripheral: CBPeripheral, key: String, value: String) {
        
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            if devices[index].setDeviceInfo(key: key, value: value) {
                // if device info has changed and list is persistent then update...
                if persistent { write() }
            }
        }
    }

    
    func reset() {
        devices = []
    }
    
    
    /// Add service to the device represented by the peripheral
    /// Write if persistent list
    func addService(peripheral: CBPeripheral, service: String) {
    
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            if !devices[index].services.contains(service) {
                devices[index].services.append(service)
                if persistent { write() }
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
    

    func read() {
        
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
        
    }
    
}
