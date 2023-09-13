//
//  GeneralSettingsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 11/09/2023.
//

import SwiftUI

struct GeneralSettingsView: View {
    
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
            Form {
                
                Toggle(isOn: $settingsManager.autoPause) {
                    Text("Auto-Pause")
                }
                
                Text("Auto pause outdoor activities when stationary.")
                    .font(.footnote).foregroundColor(.gray)

                Toggle(isOn: $settingsManager.avePowerZeros) {
                    Text("Ave. Power - include zeros")
                }

                Text("Include zeros in average power calculation.")
                    .font(.footnote).foregroundColor(.gray)

                Toggle(isOn: $settingsManager.aveCadenceZeros) {
                    Text("Ave. Cadence - include zeros")
                }

                Text("Include zeros in average cadence calculation.")
                    .font(.footnote).foregroundColor(.gray)


            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear(perform: settingsManager.save)
        }
        

}

struct GeneralSettingsView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    
    static var previews: some View {
        GeneralSettingsView(settingsManager: settingsManager)
    }
}
