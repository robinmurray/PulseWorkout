//
//  DeviceList.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 23/03/2023.
//

import Foundation
import CoreBluetooth

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


    mutating func setDeviceInfo(key: String, value: String) {
        deviceInfo[key] = value
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

struct DeviceList: CustomStringConvertible {
    var description: String {
        return "Device List description <HERE>"
    }
    
    var devices: [BTDevice]
    var serviceConnectCallback: [CBUUID: (Bool) -> Void] = [:]

    func deviceFromPeripheral(peripheral: CBPeripheral) -> BTDevice {
        
        return BTDevice(id: peripheral.identifier, name: peripheral.name ?? "Unknown", services: [], deviceInfo: [:])
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
            print("new service connect: \(service)")
            if (serviceConnectCallback[CBUUID(string: service)] != nil) {
                serviceConnectCallback[CBUUID(string: service)]!(true)
            }
        }

        for service in serviceDisconnects {
            print("new service disconnect: \(service)")
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
            print("new service connect: \(service)")
            if (serviceConnectCallback[CBUUID(string: service)] != nil) {
                serviceConnectCallback[CBUUID(string: service)]!(true)
            }
        }

        for service in serviceDisconnects {
            print("new service disconnect: \(service)")
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
            devices[index].setDeviceInfo(key: key, value: value)
            
        }
    }
    
    mutating func setDeviceInfo(peripheral: CBPeripheral, key: String, value: String) {
        
        if let index = devices.firstIndex(where: { $0.id == peripheral.identifier }) {
            devices[index].setDeviceInfo(key: key, value: value)
            
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

