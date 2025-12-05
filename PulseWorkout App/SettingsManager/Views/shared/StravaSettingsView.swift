//
//  StravaSettingsView.swift
//  PulseWorkout
//
//  Created by Robin Murray on 27/02/2025.
//

import SwiftUI

private func getFetchDate() -> Date {
    var components = DateComponents()
    components.month = 1
    components.day = 1
    let currentYear: Int = Calendar.current.dateComponents([.year], from: Date.now).year ?? 2025
    components.year = currentYear - 1
    return Calendar.current.date(from: components)!
}

struct StravaSettingsView: View {
    @ObservedObject var settingsManager: SettingsManager = SettingsManager.shared

    @State private var stravaFetchFromDate: Date
    var dataCache: DataCache
    
    init() {
        self.stravaFetchFromDate = getFetchDate()
        self.dataCache = DataCache.shared
    }
    
    var body: some View {
        Form {
            
            VStack {
                Toggle(isOn: $settingsManager.stravaEnabled) {
                    Text("Enable Strava Integration").bold()
                }
                Divider()
                
                HStack {
                    Text("Authentication Details")
                    Spacer()
                }
                VStack {
                    HStack {
                        Text("ClientId: ")
                        TextField(
                                "ClientId",
                                value: $settingsManager.stravaClientId,
                                format: .number.grouping(.never)
                        ) // .textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        
                        Text("Client Secret: ")
                        TextField(
                                "Client Secret",
                                text: $settingsManager.stravaClientSecret
                        ) // .textFieldStyle(.roundedBorder)
                    }
                }
                .disabled(!settingsManager.stravaEnabled)

                HStack {
                    Text("Strava authentication detials to connect to your Strava profile.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Spacer()
                }

            }
            
            VStack {
                Toggle(isOn: $settingsManager.stravaFetch) {
                    Text("Enable fetch from Strava")
                }
                .disabled(!settingsManager.stravaEnabled)
                HStack {
                    Text("New activities will be fetched from Strava when activity history list is refreshed.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }
            }

            VStack {
                Toggle(isOn: $settingsManager.stravaSave) {
                    Text("Enable save to Strava")
                }
                .disabled(!settingsManager.stravaEnabled)
                HStack {
                    Text("Enable saving activities to Strava - options configured below.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }
               
            }
            VStack {
                VStack {
                    Toggle(isOn: $settingsManager.stravaSaveByProfile) {
                        Text("Set save options by activity profile")
                    }
                    HStack {
                        Text("If enabled, then save options are configured within activity profiles. If not enabled, then save options are the same for all activity profiles and configured in the option below.")
                            .font(.footnote).foregroundColor(.gray)
                        Spacer()
                    }
                    
                    Toggle(isOn: $settingsManager.stravaSaveAll) {
                        Text("Auto-save all activities to Strava")
                    }.disabled(settingsManager.stravaSaveByProfile)
                    HStack {
                        Text("If enabled, then all new activities will be automatically saved to Strava. If not enabled, then a button is provided on each activity detail screen to optionally save to Strava")
                            .font(.footnote).foregroundColor(.gray)
                        Spacer()
                    }
                    
                }.disabled((!settingsManager.stravaSave) || (!settingsManager.stravaEnabled))
                
            }
            
            #if os(iOS)
            GroupBox(label:
                        HStack {
                Spacer()
                Button("Fetch/Refresh Strava Records", action: {
                    StravaFetchLatestActivities(after: stravaFetchFromDate,
                                                completionHandler: { },
                                                dataCache: dataCache).execute()
                })
                    .buttonStyle(.borderedProminent)
                Spacer()
            }
                   // Label("Fetch/Refresh Strava Records", systemImage: "location.circle")
              //  .foregroundColor(.orange)
            ) {
                VStack {

                    DatePicker(
                            "From",
                            selection: $stravaFetchFromDate,
                            displayedComponents: [.date]
                        )

                    HStack {
                        Text("Perform initial fetch of Strava data - pulling all records from this date. Or, perform a refresh of Strava data, overwriting all records from this date.")
                            .font(.footnote).foregroundColor(.gray)
                        Spacer()
                    }
                }
                
            }
            .disabled((!settingsManager.stravaEnabled) || (!settingsManager.stravaFetch))
            
            #endif
        }
        .navigationTitle("Strava Integration")
        .onDisappear(perform: settingsManager.save)
        
    }

}

#Preview {

    StravaSettingsView()
}
