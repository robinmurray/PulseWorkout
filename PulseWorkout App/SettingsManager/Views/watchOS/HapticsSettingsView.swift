//
//  HapticsSettingsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 03/11/2024.
//

import SwiftUI

struct HapticsSettingsView: View {
    
    @ObservedObject var settingsManager: SettingsManager = SettingsManager.shared
    
    var body: some View {
        Form {

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
                HStack {
                    Text("The haptic to play on heartrate alarm limits.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }
            }
            
            VStack {
                    
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
                
                HStack {
                    Text("The maximum number of times the haptic will be repeated when heart rate remains above high limit / below low limit.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }

            }

        }
        .navigationTitle {
            Label("Haptics", systemImage: "applewatch.radiowaves.left.and.right")
            .foregroundColor(.teal) }
        .onDisappear(perform: settingsManager.save)

    }
        

}


#Preview {

    HapticsSettingsView()
}
