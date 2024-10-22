//
//  BTDeviceView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 25/02/2023.
//

import SwiftUI

struct BTDeviceView: View {
    
    var btDevice: BTDevice
    
    init(btDevice: BTDevice) {
        self.btDevice = btDevice
        
    }
    
    var body: some View {

            VStack {
                HStack {
                    Text(btDevice.name)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    Spacer()
                    
                }
                HStack {
                    Text(btDevice.connectionState == .connected ? "Connected" : "Disconnected" )
                        .dynamicTypeSize(.xSmall)
                        
                    Spacer()
                }
        }
    }
}

struct BTDeviceView_Previews: PreviewProvider {
    static var device = BTDevice(id: UUID(uuidString: "B1D7C9D0-12AC-FABC-FC29-B00EDE23F68E")!, name: "TICKR C703", services: ["Service 1", "Service 2"], deviceInfo: [:])

    static var previews: some View {
        BTDeviceView(btDevice: device)
    }
}
