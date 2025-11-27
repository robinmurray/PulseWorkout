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

private func setStravaFetchDateText() -> String {
    let savedStravaFetchDate  = UserDefaults.standard.integer(forKey: "stravaFetchDate")
    let offsetFetchedDate = savedStravaFetchDate -
        (UserDefaults.standard.integer(forKey: "stravaFetchDateOffset") * 24 * 60 * 60)
    let fetchDate = Date(timeIntervalSince1970: TimeInterval(offsetFetchedDate))

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "d.M.yyyy"

    return dateFormatter.string(from: fetchDate)
}

private let MAX_DAYS_OFFSET: Int = 20
private let DAYS_OFFSET_INCREMENT: Int = 5

private func incrementFetchDateOffset() {
    let currentOffset = UserDefaults.standard.integer(forKey: "stravaFetchDateOffset")
    
    UserDefaults.standard.set(min(currentOffset + DAYS_OFFSET_INCREMENT,
                                  MAX_DAYS_OFFSET),
                              forKey: "stravaFetchDateOffset")
}

private func atMaximumOffset() -> Bool {
    return (UserDefaults.standard.integer(forKey: "stravaFetchDateOffset") >= MAX_DAYS_OFFSET)
}

struct SettingsResetView: View {
    @ObservedObject var settingsManager: SettingsManager = SettingsManager.shared
    @State var buildingStatistics: Bool = false
    @StateObject var analysingActivityProgress: AsyncProgress = AsyncProgress()
    @StateObject var buildingStatisticsProgress: AsyncProgress = AsyncProgress()
    @State var stravaFetchDateText: String
    @State var savedStravaFetchDate: Int
    

    
    init() {
        savedStravaFetchDate = UserDefaults.standard.integer(forKey: "stravaFetchDate")
        stravaFetchDateText = setStravaFetchDateText()
    }
    
    var body: some View {
        Form {
            Text("Version: \(getAppVersion()) (Build: \(getBuildNumber()))")
            
                VStack {
                    HStack {
                        Button("Clear local cache") {
                            clearCache()
                        }.buttonStyle(.bordered)
                            .tint(Color.blue)
                        
                        Spacer()
                    }

                    
                    HStack {
                        Text("Delete locally stored activities that have not been uploaded to cloud storage.")
                            .font(.footnote).foregroundColor(.gray)
                        Spacer()
                    }

                }

            #if os(iOS)
            VStack {
                HStack {
                    Button(action: {
                        if !buildingStatisticsProgress.inProgress {
                            buildingStatisticsProgress.start(asyncProgressModel: AsyncProgressModel.indefinite, title: "Building Statistics...")
                            
                            StatisticsManager.shared.buildStatistics(asyncProgressNotifier: buildingStatisticsProgress)
                            

                        }

                    })
                    {
                        Text("Rebuild Statistics")
                    }
                    .buttonStyle(.bordered)
                        .tint(Color.blue)
                        .disabled(buildingStatisticsProgress.inProgress)
                    
                    Spacer()
                }

                
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
                HStack {
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
                    .buttonStyle(.bordered)
                        .tint(Color.blue)
                        .disabled(analysingActivityProgress.inProgress)
                    Spacer()
                }

                
                if analysingActivityProgress.displayProgressView {
                    AsyncProgressView(asyncProgress: analysingActivityProgress)
                }
                
                HStack {
                    Text("Re-analyze and update all activity records.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }

            }
            
            // Reset / change strava fetch date to re-fetch activities from Strava
            if savedStravaFetchDate != 0 {
                VStack {
                    HStack {
                        Button(action: {
                            incrementFetchDateOffset()
                            stravaFetchDateText = setStravaFetchDateText()
                        })
                        {
                            Text("Set Strava Fetch Back 5 Days")
                        }
                        .buttonStyle(.bordered)
                        .tint(Color.blue)
                        .disabled(atMaximumOffset())
                        
                        Spacer()
                        Image("StravaIcon").resizable().frame(width: 30, height: 30)
                    }

                    
                    HStack {
                        Text("Current Date: \(stravaFetchDateText)")
                        Spacer()

                    }

                    
                    HStack {
                        Text("Force re-fetch of records from Strava on next pull from Strava - Set to the number of days to go back.")
                            .font(.footnote).foregroundColor(.gray)
                        Spacer()
                    }
                }
            }

            #endif
            
            }
            .navigationTitle("Reset")
            .onDisappear(perform: settingsManager.save)
            .onAppear(perform: {stravaFetchDateText = setStravaFetchDateText()})
        }
        

}

#Preview {

    SettingsResetView()
}
