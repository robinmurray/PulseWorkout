//
//  AutoPauseSettingsView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 01/11/2024.
//

import SwiftUI

struct AutoPauseSettingsView: View {
    
    @ObservedObject var settingsManager: SettingsManager = SettingsManager.shared
    
    var body: some View {
        Form {
            
            HStack {
                Text("Settings for activity profiles with Auto-pause enabled.")
                Spacer()
            }

            VStack {
                HStack {
                    Text("Pause below:")
                    Spacer()
                    
                    Stepper {
                        HStack {
                            Spacer()
                            Text(String(format: "%.1f", settingsManager.autoPauseSpeed) + " km/h")
                                .foregroundStyle(.orange)
                                .fontWeight(.bold)
                        }

                    } onIncrement: {
                        
                        settingsManager.autoPauseSpeed += 0.1
                        
                        settingsManager.autoResumeSpeed = max(settingsManager.autoPauseSpeed,
                                                              settingsManager.autoResumeSpeed)
                    } onDecrement: {
                        
                        settingsManager.autoPauseSpeed = max(settingsManager.autoPauseSpeed - 0.1, 0)
                    }

                }
                
                HStack {
                    Text("Start auto-pause when speed drops below this setting for longer than 'Mminumu Duration'.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }
            }
            
            VStack {
                HStack {
                    Text("Resume above:")
                    Spacer()
                    
                    Stepper {
                        HStack {
                            Spacer()
                            Text(String(format: "%.1f", settingsManager.autoResumeSpeed) + " km/h")
                                .foregroundStyle(.orange)
                                .fontWeight(.bold)
                        }
                    } onIncrement: {
                        
                        settingsManager.autoResumeSpeed += 0.1
                        
                    } onDecrement: {
                        settingsManager.autoResumeSpeed  = max(settingsManager.autoResumeSpeed - 0.1, 0)
                        settingsManager.autoPauseSpeed = min(settingsManager.autoPauseSpeed,
                                                             settingsManager.autoResumeSpeed)
                        
                    }
                }
                                
                HStack {
                    Text("Resume paused activity when speed goes above this setting.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }
            }
            
            VStack {
                HStack {
                    Text("Minimum duration:")
                    Spacer()
                    
                    Stepper {
                        HStack {
                            Spacer()
                            Text(String(settingsManager.minAutoPauseSeconds) + " Sec")
                                .foregroundStyle(.orange)
                                .fontWeight(.bold)
                        }
                    } onIncrement: {
                        
                        settingsManager.minAutoPauseSeconds += 1
                            
                    } onDecrement: {
                        settingsManager.minAutoPauseSeconds  = max(settingsManager.minAutoPauseSeconds - 1, 0)

                    }
                }

                HStack {
                    Text("Only register auto-pauses when they are greater than this duration.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }

            }

        }
        .navigationTitle("Auto-Pause")
       // .foregroundColor(.orange)
        .onDisappear(perform: settingsManager.save)

    }

}


#Preview {
    
    AutoPauseSettingsView()
}
