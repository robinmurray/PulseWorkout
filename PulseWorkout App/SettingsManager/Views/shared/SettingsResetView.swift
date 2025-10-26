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
    @State var buildingStatistics: Bool = false
    @StateObject var analysingActivityProgress: AsyncProgress = AsyncProgress()
    @StateObject var buildingStatisticsProgress: AsyncProgress = AsyncProgress()

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
                Button(action: {
                    if !buildingStatisticsProgress.inProgress {
                        buildingStatisticsProgress.start(asyncProgressModel: AsyncProgressModel.indefinite, title: "Building Statistics...")
                        
                        StatisticsManager.shared.buildStatistics(asyncProgressNotifier: buildingStatisticsProgress)
                        

                    }

                })
                {
                    Text("Rebuild Statistics")
                }
                .buttonStyle(.borderedProminent)
                    .tint(Color.blue)
                    .disabled(buildingStatisticsProgress.inProgress)
                
                if buildingStatisticsProgress.displayProgressView {
                    AsyncProgressView(asyncProgress: buildingStatisticsProgress)
                }
                
                HStack {
                    Text("Rebuild all statistics.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }

            }
            
            
            #endif
            
            
            #if os(iOS)
            VStack {
                Button(action: {
                    if !analysingActivityProgress.inProgress {
                        analysingActivityProgress.start(asyncProgressModel: AsyncProgressModel.indefinite, title: "Analyzing Activities...")
                        
                        CKProcessAllActivityRecords(
                            recordProcessFunction: analyzeActivity,
                            asyncProgressNotifier: analysingActivityProgress).execute()
                    }

                })
                {
                    Text("Re-analyze Activities")
                }
                .buttonStyle(.borderedProminent)
                    .tint(Color.blue)
                    .disabled(analysingActivityProgress.inProgress)
                
                if analysingActivityProgress.displayProgressView {
                    AsyncProgressView(asyncProgress: analysingActivityProgress)
                }
                
                HStack {
                    Text("Re-analyze and update all activity records.")
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
