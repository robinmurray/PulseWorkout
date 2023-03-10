//
//  BTDeviceDiscoverView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 03/02/2023.
//

import SwiftUI

struct BTDeviceDiscoverView: View {

    @ObservedObject var workoutManager: WorkoutManager
    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }

    @State private var selectedDevice: String?
    
    var body: some View {
        
        VStack{

            Group {
                List(workoutManager.bluetoothManager!.discoveredDevices) { device in
                    BTDiscoveredDeviceView(btDevice: device, bluetoothManager: workoutManager.bluetoothManager!)
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
       
        workoutManager.appState = .initial
    }

}

struct BTDeviceDiscoverView_Previews: PreviewProvider {
    
    static var workoutManager = WorkoutManager()

    static var previews: some View {
        BTDeviceDiscoverView(workoutManager: workoutManager)
    }
}
