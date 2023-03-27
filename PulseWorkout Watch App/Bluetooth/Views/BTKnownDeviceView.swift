//
//  BTKnownDeviceView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 25/02/2023.
//

import SwiftUI

struct BTKnownDeviceView: View {
    var btDevice: BTDevice
    @ObservedObject var btManager: BTDevicesController
    
    init(btDevice: BTDevice, btManager: BTDevicesController) {
        self.btDevice = btDevice
        self.btManager = btManager
        
    }
    
    var body: some View {
        HStack {
            BTDeviceView(btDevice: btDevice)
            Spacer()
            NavigationLink(destination: BTDetailDeviceView(bluetoothManager: btManager, btDevice: btDevice)) {
                Image(systemName: "info.circle")
                
            }
            .foregroundColor(Color.blue)
            .font(.title)
            .frame(width: 40, height: 40)
            .background(Color.clear)
            .clipShape(Circle())
            .buttonStyle(PlainButtonStyle())
        }
    }
}

struct BTKnownDeviceView_Previews: PreviewProvider {
    static var device = BTDevice(id: UUID(uuidString: "B1D7C9D0-12AC-FABC-FC29-B00EDE23F68E")!, name: "TICKR C703", services: ["Service 1", "Service 2"], deviceInfo: [:])

    static var btManager: BTDevicesController = BTDevicesController( requestedServices: nil)
    
    static var previews: some View {
        BTKnownDeviceView(btDevice: device, btManager: btManager)
    }
}
