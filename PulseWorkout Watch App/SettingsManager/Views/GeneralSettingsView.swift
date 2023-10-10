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


                Picker("Haptic Type", selection: $settingsManager.hapticType) {
                    ForEach(hapticTypes) { hapticType in
                        Text(hapticType.name).tag(hapticType.self)
                    }
                }
                .font(.headline)
                .foregroundColor(Color.blue)
                .fontWeight(.bold)
                .listStyle(.carousel)
                .onChange(of: settingsManager.hapticType,
                          perform: {newValue in WKInterfaceDevice.current().play(settingsManager.hapticType)} )
                
                
                Text("Maximum haptic repeat")
                Stepper(value: $settingsManager.maxAlarmRepeatCount,
                        in: 1...5,
                        step: 1) { Text("\(settingsManager.maxAlarmRepeatCount)")
                }
                .font(.headline)
                .fontWeight(.light)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.20)
                .frame(width:160, height: 40, alignment: .topLeading)


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
