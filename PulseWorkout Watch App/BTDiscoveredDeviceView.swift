//
//  BTDiscoveredDeviceView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 25/02/2023.
//

import SwiftUI

struct BTDiscoveredDeviceView: View {
    var btDevice: BTDevice
    @ObservedObject var btManager: BTDevicesController

    init(btDevice: BTDevice, btManager: BTDevicesController) {
        self.btDevice = btDevice
        self.btManager = btManager
    }
    
    func connectDevice() {

        btManager.connectDevice(device: btDevice)

    }
    
    var body: some View {
        HStack {
            VStack {
                BTDeviceView(btDevice: btDevice)
                
                HStack {
                    Text(btDevice.connected(bluetoothManager: btManager) ? "Connected" : btManager.connectableDevices.contains(device: btDevice) ? "": "Connecting")
                    Spacer()
                    VStack{
                        Button(action: connectDevice) {
                            Image(systemName: "link.circle")
                        }
                        .foregroundColor( btManager.connectableDevices.contains(device: btDevice) ? Color.yellow : Color.gray)
                        .font(.title)
                        .frame(width: 40, height: 40)
                        .background(Color.clear)
                        .clipShape(Circle())
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("Connect")
                            .foregroundColor( btManager.connectableDevices.contains(device: btDevice) ? Color.yellow : Color.gray)
                        
                    }
                }
            }
        }
    }
}

struct BTDiscoveredDeviceView_Previews: PreviewProvider {
    static var device = BTDevice(id: UUID(uuidString: "B1D7C9D0-12AC-FABC-FC29-B00EDE23F68E")!, name: "TICKR C703", services: [])

    static var btManager: BTDevicesController = BTDevicesController(requestedServices: nil)

    static var previews: some View {
        BTDiscoveredDeviceView(btDevice: device,
                               btManager: btManager)
    }
}
