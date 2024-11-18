//
//  GeneralSettingsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 31/10/2024.
//

import SwiftUI

struct GeneralSettingsView: View {
    
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
            Form {
                Section(header: Text("Auto-Pause Settings")) {
                    VStack {
                        
                        Text("Auto pause outdoor activities when stationary.")
                            .font(.footnote).foregroundColor(.gray)


                        
                        HStack {
                            Text("Pause below:")
                            Spacer()
                        }
                        Stepper {
                            Text(String(format: "%.1f", settingsManager.autoPauseSpeed) + " km/h")
                                .font(.body)
                            Spacer()
                        } onIncrement: {
                            
                            settingsManager.autoPauseSpeed += 0.1
                                
                            settingsManager.autoResumeSpeed = max(settingsManager.autoPauseSpeed,
                                                                  settingsManager.autoResumeSpeed)
                        } onDecrement: {

                            settingsManager.autoPauseSpeed = max(settingsManager.autoPauseSpeed - 0.1, 0)
                        }
                        .font(.body)
                        .fontWeight(.light)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.20)
                        .frame(width:160, height: 40, alignment: .topLeading)

                        
                        HStack {
                            Text("Resume above:")
                            Spacer()
                        }

                        Stepper {
                            Text(String(format: "%.1f", settingsManager.autoResumeSpeed) + " km/h")
                                .font(.body)
                        } onIncrement: {
                            
                            settingsManager.autoResumeSpeed += 0.1
                                
                        } onDecrement: {
                            settingsManager.autoResumeSpeed  = max(settingsManager.autoResumeSpeed - 0.1, 0)
                            settingsManager.autoPauseSpeed = min(settingsManager.autoPauseSpeed,
                                                                    settingsManager.autoResumeSpeed)

                        }
                        .font(.body)
                        .fontWeight(.light)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.20)
                        .frame(width:160, height: 40, alignment: .topLeading)
        
                        HStack {
                            Text("Minimum duration:")
                            Spacer()
                        }
                        

                        Stepper {
                            Text(String(settingsManager.minAutoPauseSeconds) + " Sec")
                                .font(.body)
                        } onIncrement: {
                            
                            settingsManager.minAutoPauseSeconds += 1
                                
                        } onDecrement: {
                            settingsManager.minAutoPauseSeconds  = max(settingsManager.minAutoPauseSeconds - 1, 0)

                        }
                        .font(.body)
                        .fontWeight(.light)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.2)
                        .frame(width:140, height: 30, alignment: .topLeading)

                        Text("Only register auto-pauses when they are greater than this duration.")
                            .font(.footnote).foregroundColor(.gray)


                    }

                }
                .font(.subheadline)

                Section(header: Text("Average Calculations")) {
                    VStack {
                        
                        Toggle(isOn: $settingsManager.aveHRPaused) {
                            Text("Ave. HR - include pauses")

                        }
                        
                        Text("Include HR in average when auto-paused.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    
                    VStack {
                        Toggle(isOn: $settingsManager.avePowerZeros) {
                            Text("Ave. Power - include zeros")
                        }

                        Text("Include zeros in average power calculation.")
                            .font(.footnote).foregroundColor(.gray)
                    }

                    VStack {
                        Toggle(isOn: $settingsManager.aveCadenceZeros) {
                            Text("Ave. Cadence - include zeros")

                        }

                        Text("Include zeros in average cadence calculation.")
                            .font(.footnote).foregroundColor(.gray)
                    }


                }
                .font(.subheadline)
          
                Section(header: Text("Cycle Power Settings")) {
                    
                    VStack {
                        Toggle(isOn: $settingsManager.use3sCyclePower) {
                            Text("Use 3s. Cycle Power")

                        }
                        
                        Text("Use 3 second average cycling power, or instantaneous power.")
                            .font(.footnote).foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text("Cycle power chart averages over:")
                        Spacer()
                    }
                    
                    Stepper {
                        Text(String(settingsManager.cyclePowerGraphSeconds) + " Sec")
                            .font(.body)
                    } onIncrement: {
                        
                        settingsManager.cyclePowerGraphSeconds = min(settingsManager.cyclePowerGraphSeconds + 1, 60)
                            
                    } onDecrement: {
                        settingsManager.cyclePowerGraphSeconds = max(settingsManager.cyclePowerGraphSeconds - 1, 1)

                    }
                    .font(.body)
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.2)
                    .frame(width:140, height: 30, alignment: .topLeading)

                    Text("Smooth the cycling power graph by averaging power output over this number of seconds.")
                        .font(.footnote).foregroundColor(.gray)
                }
                .font(.subheadline)
                
                Section(header: Text("Haptics")) {
                    VStack {

                        HStack {
                            Text("Maximum haptic repeat")
                            Spacer()
                        }

                        Stepper(value: $settingsManager.maxAlarmRepeatCount,
                                in: 1...5,
                                step: 1) { Text("\(settingsManager.maxAlarmRepeatCount)")
                                .font(.body)
                        }
                        .font(.body)
                        .fontWeight(.light)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.20)
                        .frame(width:160, height: 40, alignment: .topLeading)

                        Text("The maximum number of times the haptic will be repeated when heart rate remains above high limit / below low limit.")
                            .font(.footnote).foregroundColor(.gray)
                    }

                }
                .font(.subheadline)


            }
            .navigationTitle("General")
            .onDisappear(perform: settingsManager.save)

        }
        

}

#Preview {
    
    var settingsManager = SettingsManager()
    
    GeneralSettingsView(settingsManager: settingsManager)
}
