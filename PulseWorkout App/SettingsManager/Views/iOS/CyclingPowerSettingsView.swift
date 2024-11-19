//
//  CyclingPowerSettingsView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 01/11/2024.
//

import SwiftUI

struct CyclingPowerSettingsView: View {
    
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        Form {
                
            VStack {
                Toggle(isOn: $settingsManager.use3sCyclePower) {
                    Text("Use 3s. Cycle Power")

                }
                
                HStack {
                    Text("Use 3 second average cycling power, or instantaneous power.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }

            }
            
            VStack {
                HStack {
                    Text("Cycle power chart averages over:")
                    Spacer()
                    Stepper {
                        HStack {
                            Spacer()
                            Text(String(settingsManager.cyclePowerGraphSeconds) + " Sec")
                                .foregroundStyle(.red)
                                .fontWeight(.bold)
                        }

                    } onIncrement: {
                        
                        settingsManager.cyclePowerGraphSeconds = min(settingsManager.cyclePowerGraphSeconds + 1, 60)
                            
                    } onDecrement: {
                        settingsManager.cyclePowerGraphSeconds = max(settingsManager.cyclePowerGraphSeconds - 1, 1)

                    }

                }
                
                HStack {
                    Text("Smooth the cycling power graph by averaging power output over this number of seconds.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }
            }
        }
        .navigationTitle("Cycling Power")
        .onDisappear(perform: settingsManager.save)

    }
        

}


#Preview {
    
    let settingsManager = SettingsManager()
    
    CyclingPowerSettingsView(settingsManager: settingsManager)
}
