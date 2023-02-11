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
        
        VStack {
            // if still `[String]` then \.self will work, otherwise make `Device` `Identifiable`
            List(workoutManager.bluetoothManager!.discoveredDevices, id: \.self) { device in
                Text(verbatim: device)
                
            }.listStyle(.carousel)
        
                Button(action: dismissView) {
                    Text("Dismiss")
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
