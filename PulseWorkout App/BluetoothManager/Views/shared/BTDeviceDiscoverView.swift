//
//  BTDeviceDiscoverView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 03/02/2023.
//

import SwiftUI

struct BTDeviceDiscoverView: View {

    @ObservedObject var bluetoothManager: BTDevicesController
    @ObservedObject var discoveredDevices: BTDeviceList
    
    init(bluetoothManager: BTDevicesController) {
        self.bluetoothManager = bluetoothManager
        self.discoveredDevices = bluetoothManager.discoveredDevices
    }

    @State private var selectedDevice: String?
    
    var body: some View {
        
        VStack{

            Group {
                List(discoveredDevices.devices) { device in
                    BTDiscoveredDeviceView(btDevice: device, btManager: bluetoothManager)
                }
                #if os(watchOS)
                .listStyle(.carousel)
                #endif

            }
            
        }
        #if os(watchOS)
        .navigationTitle {
            Label("Discover Sensors", systemImage: "badge.plus.radiowaves.right")
                .foregroundColor(.blue)
        }
        #endif
        .onAppear {
            bluetoothManager.discoverDevices()
        }
        .onDisappear {
            bluetoothManager.stopDiscoverDevices()
        }
        
    }
}

struct BTDeviceDiscoverView_Previews: PreviewProvider {
    
    static var bluetoothManager = BTDevicesController(requestedServices: nil)

    
    static var previews: some View {
        BTDeviceDiscoverView(bluetoothManager: bluetoothManager)
    }
}
