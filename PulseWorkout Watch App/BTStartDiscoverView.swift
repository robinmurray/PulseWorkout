//
//  DevicesView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 04/02/2023.
//

import SwiftUI

struct BTStartDiscoverView: View {
    
    @ObservedObject var workoutManager: WorkoutManager
    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }


    var body: some View {
 
        Group {

        VStack {
            List(workoutManager.bluetoothManager!.knownDevices.devices) { device in
                BTKnownDeviceView(btDevice: device, btManager: workoutManager.bluetoothManager!)
            }
            .listStyle(.carousel)

            Button(action: discoverDevices) {
                Text("Discover Devices")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.blue)
            .disabled(workoutManager.bluetoothManager?.centralManager.state != .poweredOn)
        }
        .navigationTitle("Devices")
        .navigationBarTitleDisplayMode(.inline)
    }
        
    }
    
    func discoverDevices() {
        workoutManager.appState = .discoverDevices
        workoutManager.bluetoothManager?.discoverDevices()
    }
}

struct BTStartDiscoverView_Previews: PreviewProvider {
    
    static var workoutManager = WorkoutManager()

    static var previews: some View {
        BTStartDiscoverView(workoutManager: workoutManager)
    }
}
