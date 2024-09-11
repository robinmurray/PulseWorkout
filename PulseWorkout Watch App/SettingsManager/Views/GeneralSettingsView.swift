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
                Section(header: Text("Auto-Pause Settings")) {
                    VStack {
                        
                        Text("Auto pause outdoor activities when stationary.")
                            .font(.footnote).foregroundColor(.gray)


                        
                        HStack {
                            Text("Pause below:")
                                .foregroundColor(.white)
                            Spacer()
                        }
                        Stepper {
                            Text(String(format: "%.1f", settingsManager.autoPauseSpeed) + " km/h")
                                .foregroundColor(.white)
                                .font(.body)
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
                                .foregroundColor(.white)
                            Spacer()
                        }

                        Stepper {
                            Text(String(format: "%.1f", settingsManager.autoResumeSpeed) + " km/h")
                                .foregroundColor(.white)
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
                                .foregroundColor(.white)
                            Spacer()
                        }
                        

                        Stepper {
                            Text(String(settingsManager.minAutoPauseSeconds) + " Sec")
                                .foregroundColor(.white)
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
                        .foregroundColor(.white)

                        Text("Only register auto-pauses when they are greater than this duration.")
                            .font(.footnote).foregroundColor(.gray)


                    }

                }
                .font(.subheadline)
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)

                Section(header: Text("Average Calculations")) {
                    VStack {
                        
                        Toggle(isOn: $settingsManager.aveHRPaused) {
                            Text("Ave. HR - include pauses")
                                .foregroundColor(.white)
                        }
                        
                        Text("Include HR in average when auto-paused.")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    
                    VStack {
                        Toggle(isOn: $settingsManager.avePowerZeros) {
                            Text("Ave. Power - include zeros")
                                .foregroundColor(.white)
                        }

                        Text("Include zeros in average power calculation.")
                            .font(.footnote).foregroundColor(.gray)
                    }

                    VStack {
                        Toggle(isOn: $settingsManager.aveCadenceZeros) {
                            Text("Ave. Cadence - include zeros")
                                .foregroundColor(.white)
                        }

                        Text("Include zeros in average cadence calculation.")
                            .font(.footnote).foregroundColor(.gray)
                    }


                }
                .font(.subheadline)
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                

                Section(header: Text("Haptics")) {
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
                            .onChange(of: settingsManager.hapticType) { oldValue, newValue in WKInterfaceDevice.current().play(settingsManager.hapticType)}
                            
                            Spacer()
                        }
                        Text("The haptic to play on heartrate alarm limits.")
                            .font(.footnote).foregroundColor(.gray)
                        
                        HStack {
                            Text("Maximum haptic repeat")
                                .foregroundColor(.white)
                            Spacer()
                        }

                        Stepper(value: $settingsManager.maxAlarmRepeatCount,
                                in: 1...5,
                                step: 1) { Text("\(settingsManager.maxAlarmRepeatCount)")
                                .foregroundColor(.white)
                                .font(.body)
                        }
                        .font(.body)
                        .fontWeight(.light)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.20)
                        .frame(width:160, height: 40, alignment: .topLeading)
                        .foregroundColor(.white)

                        Text("The maximum number of times the haptic will be repeated when heart rate remains above high limit / below low limit.")
                            .font(.footnote).foregroundColor(.gray)
                    }

                }
                .font(.subheadline)
                .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)


            }
            .navigationTitle{
                Label("General", systemImage: "folder")
                    .foregroundColor(.white)
            }
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
