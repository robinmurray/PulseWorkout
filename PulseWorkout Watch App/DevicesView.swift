//
//  DevicesView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 04/02/2023.
//

import SwiftUI

struct DevicesView: View {
    
    @ObservedObject var profileData: ProfileData
    
    init(profileData: ProfileData) {
        self.profileData = profileData
    }

    var body: some View {
        
        VStack {
            Button(action: discoverDevices) {
                Text("Discover Devices")
            }
        }
        .navigationTitle("Devices")
        .navigationBarTitleDisplayMode(.inline)
    }

    
    func discoverDevices() {
//        profileData.bluetoothManager?.resetDiscoveredDevices()
//        profileData.bluetoothManager?.centralManager.scanForPeripherals(withServices: nil)
        profileData.appState = .discoverDevices
    }
}

struct DevicesView_Previews: PreviewProvider {
    
    static var profileData = ProfileData()

    static var previews: some View {
        DevicesView(profileData: profileData)
    }
}
