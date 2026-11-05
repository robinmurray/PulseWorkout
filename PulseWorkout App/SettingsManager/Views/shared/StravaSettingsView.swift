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
    @ObservedObject var stravaRefreshParameters = SettingsManager.shared.stravaRefreshParameters

    @State private var stravaFetchFromDate: Date
    @State private var showingLastFetchDetailsPopup = false
    @State private var showingFetchDetailsPopup = false

    var dataCache: DataCache
    
    init() {
        self.stravaFetchFromDate = getFetchDate()
        self.dataCache = DataCache.shared
    }
    
    var body: some View {

        GeometryReader { geometry in


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
                    
                    Button(action: {
                        if !stravaRefreshParameters.inProgress {
                            settingsManager.submitNewFullStravaRefreshTask(from: stravaFetchFromDate)
                        }
                        showingFetchDetailsPopup = true
                    }) {
                        if stravaRefreshParameters.inProgress {
                            HStack {
                                Text("Strava fetch in progress")
                                ProgressView()
                            }
                            
                        } else {
                            Text("Fetch/Refresh Strava Records")
                        }
                    }
                    .buttonStyle(.glass)
                    .glassEffect(.clear.tint(.blue))
                    .popover(isPresented: $showingFetchDetailsPopup,
                             attachmentAnchor: .point(.top),
                             arrowEdge: .bottom) {
                        BGStravaFetchProgresssView(refreshParameters: stravaRefreshParameters)
                            .presentationCompactAdaptation(.popover)
                            .presentationBackground(.regularMaterial)
                            .frame(width: geometry.size.width * 0.8)
                    }
                    
                    Spacer()
                    
                }
                )
                {
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
                        
                        if !stravaRefreshParameters.inProgress {
                            HStack {
                                Button("View last fetch results") {
                                    showingLastFetchDetailsPopup = true
                                }
                                .buttonStyle(.automatic)
                                .popover(isPresented: $showingLastFetchDetailsPopup,
                                         attachmentAnchor: .point(.top),
                                         arrowEdge: .bottom) {
                                        BGStravaFetchProgresssView(refreshParameters: stravaRefreshParameters)
                                            .presentationCompactAdaptation(.popover)
                                            .presentationBackground(.regularMaterial)
                                            .frame(width: geometry.size.width * 0.8)
                                    }
                                
                                Spacer()
                            }
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

}

#Preview {

    StravaSettingsView()
}
