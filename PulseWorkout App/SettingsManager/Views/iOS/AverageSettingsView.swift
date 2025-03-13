//
//  AverageSettingsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 01/11/2024.
//

import SwiftUI

struct AverageSettingsView: View {
    
    @ObservedObject var settingsManager: SettingsManager = SettingsManager.shared
    
    var body: some View {
        Form {

            VStack {
                
                Toggle(isOn: $settingsManager.aveHRPaused) {
                    Text("Ave. HR - include pauses")

                }
                HStack {
                    Text("Include HR in average when auto-paused.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Spacer()
                }

            }
            
            VStack {
                Toggle(isOn: $settingsManager.avePowerZeros) {
                    Text("Ave. Power - include zeros")
                }
                HStack {
                    Text("Include zeros in average power calculation.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }
            }

            VStack {
                Toggle(isOn: $settingsManager.aveCadenceZeros) {
                    Text("Ave. Cadence - include zeros")

                }
                HStack {
                    Text("Include zeros in average cadence calculation.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }
            }


        }
        .navigationTitle("Average Calculations")
        .onDisappear(perform: settingsManager.save)

    }
        

}


#Preview {
    
    AverageSettingsView()
}
