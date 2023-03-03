//
//  BTDiscoveredDeviceView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 25/02/2023.
//

import SwiftUI

struct BTDiscoveredDeviceView: View {
    var btDevice: BTDevice
    
    init(btDevice: BTDevice) {
        self.btDevice = btDevice
        
    }
    
    func connectDevice() {
        
    }
    var body: some View {
        HStack {
            VStack {
                BTDeviceView(btDevice: btDevice)
                }
            VStack{
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

            }

        }
    }
}

struct BTDiscoveredDeviceView_Previews: PreviewProvider {
    static var device = BTDevice(id: UUID(uuidString: "B1D7C9D0-12AC-FABC-FC29-B00EDE23F68E")!, name: "TICKR C703", services: [])

    static var previews: some View {
        BTDiscoveredDeviceView(btDevice: device)
    }
}
