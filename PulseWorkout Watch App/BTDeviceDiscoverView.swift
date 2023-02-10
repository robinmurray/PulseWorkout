//
//  BTDeviceDiscoverView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 03/02/2023.
//

import SwiftUI

struct BTDeviceDiscoverView: View {

    @ObservedObject var profileData: ProfileData
    
    init(profileData: ProfileData) {
        self.profileData = profileData
    }

    @State private var selectedDevice: String?
    
    var body: some View {
        
        VStack {
            // if still `[String]` then \.self will work, otherwise make `Device` `Identifiable`
            List(profileData.bluetoothManager!.discoveredDevices, id: \.self) { device in
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
       
        profileData.appState = .initial
    }

}

struct BTDeviceDiscoverView_Previews: PreviewProvider {
    
    static var profileData = ProfileData()

    static var previews: some View {
        BTDeviceDiscoverView(profileData: profileData)
    }
}
