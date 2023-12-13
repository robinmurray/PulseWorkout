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
                
                VStack {
                    Toggle(isOn: $settingsManager.autoPause) {
                        Text("Auto-Pause")
                    }
                    
                    Text("Auto pause outdoor activities when stationary.")
                        .font(.footnote).foregroundColor(.gray)


                    
                    HStack {
                        Text("Pause below:")
                        Spacer()
                    }
                    Stepper {
                        Text(String(format: "%.1f", settingsManager.autoPauseSpeed) + " km/h")
                    } onIncrement: {
                        
                        settingsManager.autoPauseSpeed += 0.1
                            
                        settingsManager.autoResumeSpeed = max(settingsManager.autoPauseSpeed,
                                                              settingsManager.autoResumeSpeed)
                    } onDecrement: {

                        settingsManager.autoPauseSpeed = max(settingsManager.autoPauseSpeed - 0.1, 0)
                    }
                    .disabled(!settingsManager.autoPause)
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
                    } onIncrement: {
                        
                        settingsManager.autoResumeSpeed += 0.1
                            
                    } onDecrement: {
                        settingsManager.autoResumeSpeed  = max(settingsManager.autoResumeSpeed - 0.1, 0)
                        settingsManager.autoPauseSpeed = min(settingsManager.autoPauseSpeed,
                                                                settingsManager.autoResumeSpeed)

                    }
                    .disabled(!settingsManager.autoPause)
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
                    } onIncrement: {
                        
                        settingsManager.minAutoPauseSeconds += 1
                            
                    } onDecrement: {
                        settingsManager.minAutoPauseSeconds  = max(settingsManager.minAutoPauseSeconds - 1, 0)

                    }
                    .disabled(!settingsManager.autoPause)
                    .font(.body)
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.2)
                    .frame(width:140, height: 30, alignment: .topLeading)

                    Text("Only register auto-pauses when they are greater than this duration.")
                        .font(.footnote).foregroundColor(.gray)


                }

                VStack {
                    
                    Toggle(isOn: $settingsManager.aveHRPaused) {
                        Text("Ave. HR - include pauses")
                    }
                    .disabled(!settingsManager.autoPause)
                    
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


                VStack {
                    HStack {
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
                        
                        Spacer()
                    }
                    Text("The haptic to play on heartrate alarm limits.")
                        .font(.footnote).foregroundColor(.gray)
                    
                    HStack {
                        Text("Maximum haptic repeat")
                        Spacer()
                    }

                    Stepper(value: $settingsManager.maxAlarmRepeatCount,
                            in: 1...5,
                            step: 1) { Text("\(settingsManager.maxAlarmRepeatCount)")
                    }
                    .font(.headline)
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.20)
                    .frame(width:160, height: 40, alignment: .topLeading)
                    
                    Text("The maximum number of times the haptic will be repeated when heart rate remains above high limit / below low limit.")
                        .font(.footnote).foregroundColor(.gray)
                }



            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onDisappear(perform: settingsManager.save)

        }
        

}

struct GeneralSettingsView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    
    static var previews: some View {
        GeneralSettingsView(settingsManager: settingsManager)
    }
}
