//
//  BTDeviceDiscoverView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 03/02/2023.
//

import SwiftUI

struct BTDeviceDiscoverView: View {

    @ObservedObject var bluetoothManager: BTDevicesController
    
    init(bluetoothManager: BTDevicesController) {
        self.bluetoothManager = bluetoothManager
    }

    @State private var selectedDevice: String?
    
    var body: some View {
        
        VStack{

            Group {
                List(bluetoothManager.discoveredDevices.devices) { device in
                    BTDiscoveredDeviceView(btDevice: device, btManager: bluetoothManager)
                }
                .listStyle(.carousel)

            }
            
        }
        .navigationTitle {
            Label("Discover Sensors", systemImage: "badge.plus.radiowaves.right")
                .foregroundColor(.blue)
        }
        .onAppear {
            bluetoothManager.discoverDevices()
        }
        .onDisappear {
            bluetoothManager.stopDiscoverDevices()
        }
        
    }
}

struct BTDeviceDiscoverView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache()
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager, settingsManager: settingsManager,
        dataCache: dataCache)
    static var bluetoothManager = liveActivityManager.bluetoothManager
    
    static var previews: some View {
        BTDeviceDiscoverView(bluetoothManager: bluetoothManager!)
    }
}
