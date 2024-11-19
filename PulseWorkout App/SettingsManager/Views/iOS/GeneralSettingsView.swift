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
