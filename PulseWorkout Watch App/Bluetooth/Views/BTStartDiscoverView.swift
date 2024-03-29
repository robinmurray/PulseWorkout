//
//  DevicesView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 04/02/2023.
//

import SwiftUI

struct BTStartDiscoverView: View {
    
    @ObservedObject var bluetoothManager: BTDevicesController
    
    init(bluetoothManager: BTDevicesController) {
        self.bluetoothManager = bluetoothManager
    }


    var body: some View {
        NavigationStack {
            Group {

            VStack {
                List(bluetoothManager.knownDevices.devices) { device in
                    BTKnownDeviceView(btDevice: device, btManager: bluetoothManager)
                }
                .listStyle(.carousel)

                NavigationLink(destination: BTDeviceDiscoverView(bluetoothManager: bluetoothManager)) {
                    Text("Discover Sensors")
                    
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.blue)
                .disabled(bluetoothManager.centralManager.state != .poweredOn)

            }
            .navigationTitle {
                Label("Sensors", systemImage: "badge.plus.radiowaves.right")
                    .foregroundColor(.blue)
            }

        }

        }
        
    }
  
    
    func discoverDevices() {
        bluetoothManager.discoverDevices()
    }
}

struct BTStartDiscoverView_Previews: PreviewProvider {
    
    static var bluetoothManager = BTDevicesController(requestedServices: nil)

    static var previews: some View {
        BTStartDiscoverView(bluetoothManager: bluetoothManager)
    }
}
