//
//  CloudConnectionsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 11/09/2023.
//

import SwiftUI


struct CloudConnectionsView: View {
    
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
            Form {
                
                Toggle(isOn: $settingsManager.saveAppleHealth) {
                    Text("Apple Health")
                }
                
                Text("Save activity summaries to apple health.")
                    .font(.footnote).foregroundColor(.gray)

                Toggle(isOn: $settingsManager.saveStrava) {
                    Text("Strava")
                }

                Text("Save activities and routes to Strava.")
                    .font(.footnote).foregroundColor(.gray)

            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear(perform: settingsManager.save)
        }
        

}

struct CloudConnectionsView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    
    static var previews: some View {
        CloudConnectionsView(settingsManager: settingsManager)
    }
}
