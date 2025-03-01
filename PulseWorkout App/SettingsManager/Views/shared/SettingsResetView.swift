//
//  SettingsResetView.swift
//  PulseWorkout
//
//  Created by Robin Murray on 27/02/2025.
//

import SwiftUI

struct SettingsResetView: View {
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        Form {

                VStack {
                    Button("Clear local cache") {
                        clearCache()
                    }.buttonStyle(.borderedProminent)
                        .tint(Color.blue)
                    
                    HStack {
                        Text("Delete locally stored activities that have not been uploaded to cloud storage.")
                            .font(.footnote).foregroundColor(.gray)
                        Spacer()
                    }

                }

            }
            .navigationTitle("Reset")
            .onDisappear(perform: settingsManager.save)
        }
        

}

#Preview {
    let settingsManager = SettingsManager()
    
    SettingsResetView(settingsManager: settingsManager)
}
