//
//  PulseWorkoutApp.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import SwiftUI

@main
struct PulseWorkout_Watch_AppApp: App {
    @Environment(\.scenePhase) private var scenePhase

    
    @ObservedObject var profileManager: ActivityProfiles
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var dataCache: DataCache

    init() {
        let mySettingsManager = SettingsManager()
        let myLocationManager = LocationManager(settingsManager: mySettingsManager)
        let myDataCache = DataCache()
        locationManager = myLocationManager
        liveActivityManager = LiveActivityManager(locationManager: myLocationManager,
                                                  settingsManager: mySettingsManager,
                                                  dataCache: myDataCache)
        profileManager = ActivityProfiles()
        settingsManager = mySettingsManager
        dataCache = myDataCache
        
    }

    var body: some Scene {
        WindowGroup {
            ContentView(liveActivityManager: liveActivityManager,
                        profileManager: profileManager,
                        dataCache: dataCache,
                        settingsManager: settingsManager,
                        locationManager: locationManager)
        }
        .onChange(of: scenePhase) { oldScenePhase, newScenePhase in
            switch newScenePhase {
                case .active:
                    liveActivityManager.appActive()
                case .inactive:
                    liveActivityManager.appInactive()
                case .background:
                    liveActivityManager.appBackground()
                default:
                    print(">> do something else in future")
            }
        }
    }
}
