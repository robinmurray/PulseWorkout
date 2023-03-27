//
//  BTDiscoveredDeviceView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 25/02/2023.
//

import SwiftUI

struct ConnectView: View {

    var btDevice: BTDevice
    @ObservedObject var btManager: BTDevicesController

    init(btDevice: BTDevice, btManager: BTDevicesController) {
        self.btDevice = btDevice
        self.btManager = btManager
    }

    var body: some View {
        VStack {
            Button(action: connectDevice) {
                Image(systemName: "link.circle")
            }
            .foregroundColor(Color.yellow)
            .font(.title)
            .frame(width: 40, height: 40)
            .background(Color.clear)
            .clipShape(Circle())
            .buttonStyle(PlainButtonStyle())
            
            Text("Connect")
                .foregroundColor(Color.yellow)
                .dynamicTypeSize(.xSmall)
                .fontWeight(.bold)

        }
    }
    
    func connectDevice() {
//        btDevice.connectionState = .connecting
        btManager.connectDevice(device: btDevice)

    }

}

struct ConnectedView: View {

    var body: some View {
        VStack {
            Image(systemName: "link.circle")
                .foregroundColor(Color.blue)
                .font(.title)
                .frame(width: 40, height: 40)

        }
    }
}

struct ConnectingView: View {

    var btDevice: BTDevice
    @ObservedObject var btManager: BTDevicesController

    init(btDevice: BTDevice, btManager: BTDevicesController) {
        self.btDevice = btDevice
        self.btManager = btManager
    }

    func cancelConnect() {
        btManager.forgetDevice(device: btDevice)
    }

    var body: some View {
        VStack {
            Button(action: cancelConnect) {
                ProgressView()
            }
            .font(.title)
            .frame(width: 40, height: 40)
            .background(Color.clear)
            .clipShape(Circle())
            .buttonStyle(PlainButtonStyle())

            
            Text("Cancel")
                .foregroundColor(Color.blue)
                .dynamicTypeSize(.xSmall)
                .fontWeight(.bold)
        }
    }
}


struct BTDiscoveredDeviceView: View {
    var btDevice: BTDevice
    @ObservedObject var btManager: BTDevicesController

    init(btDevice: BTDevice, btManager: BTDevicesController) {
        self.btDevice = btDevice
        self.btManager = btManager
    }
    


    
    func statusView() -> AnyView {

        if btManager.knownDevices.contains(device: btDevice) {
            return AnyView(ConnectedView())

        }
        if !btManager.connectableDevices.contains(device: btDevice) {
            return AnyView(ConnectView(btDevice: btDevice, btManager: btManager))

        }
        return AnyView(ConnectingView(btDevice: btDevice, btManager: btManager))
    }
    
    
    var body: some View {
        HStack {
            BTDeviceView(btDevice: btDevice)
            Spacer()
            statusView()

     
        }
    }
}

struct BTDiscoveredDeviceView_Previews: PreviewProvider {
    static var device = BTDevice(id: UUID(uuidString: "B1D7C9D0-12AC-FABC-FC29-B00EDE23F68E")!, name: "TICKR C703", services: [], deviceInfo: [:])

    static var btManager: BTDevicesController = BTDevicesController(requestedServices: nil)

    static var previews: some View {
        BTDiscoveredDeviceView(btDevice: device,
                               btManager: btManager)
    }
}
