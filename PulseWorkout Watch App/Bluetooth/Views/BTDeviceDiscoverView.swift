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

                Button(action: dismissView) {
                        Text("Dismiss")
                }

            }
            
        }
        .navigationTitle("Discover Devices")
        .navigationBarTitleDisplayMode(.inline)
               
    }
    
    func dismissView() {
        bluetoothManager.stopDiscoverDevices()
//        workoutManager.appState = .initial
    }

}

struct BTDeviceDiscoverView_Previews: PreviewProvider {
    
    static var workoutManager = WorkoutManager()
    static var bluetoothManager = workoutManager.bluetoothManager
    
    static var previews: some View {
        BTDeviceDiscoverView(bluetoothManager: bluetoothManager!)
    }
}
