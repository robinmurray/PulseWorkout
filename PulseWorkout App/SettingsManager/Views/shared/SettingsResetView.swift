//
//  SettingsResetView.swift
//  PulseWorkout
//
//  Created by Robin Murray on 27/02/2025.
//

import SwiftUI

func getBuildNumber() -> String {
    if let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
        return buildNumber
    }
    return "Unknown"
}

func getAppVersion() -> String {
    if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
        return appVersion
    }
    return "Unknown"
}

struct SettingsResetView: View {
    @ObservedObject var settingsManager: SettingsManager = SettingsManager.shared
    
    var body: some View {
        Form {
            Text("Version: \(getAppVersion()) (Build: \(getBuildNumber()))")
            
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

            #if os(iOS)
            VStack {
                Button("Rebuild Statistics") {
                    StatisticsManager.shared.buildStatistics()
                }.buttonStyle(.borderedProminent)
                    .tint(Color.blue)
                
                HStack {
                    Text("Rebuild all statistics.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }

            }
            #endif
            }
            .navigationTitle("Reset")
            .onDisappear(perform: settingsManager.save)
        }
        

}

#Preview {

    SettingsResetView()
}
