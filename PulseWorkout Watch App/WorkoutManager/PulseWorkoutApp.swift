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
    @ObservedObject var activityDataManager: ActivityDataManager
    @ObservedObject var workoutManager: WorkoutManager
    @ObservedObject var settingsManager: SettingsManager

    init() {
        let mySettingsManager = SettingsManager()
        let myActivityDataManager = ActivityDataManager(settingsManager: mySettingsManager)
        let myLocationManager = LocationManager(activityDataManager: myActivityDataManager, settingsManager: mySettingsManager)
        locationManager = myLocationManager
        workoutManager = WorkoutManager(locationManager: myLocationManager,
                                        activityDataManager: myActivityDataManager,
                                        settingsManager: mySettingsManager)
        profileManager = ActivityProfiles()
        activityDataManager = myActivityDataManager
        settingsManager = mySettingsManager
        
    }

    var body: some Scene {
        WindowGroup {
            ContentView(workoutManager: workoutManager,
                        profileManager: profileManager,
                        activityDataManager: activityDataManager,
                        settingsManager: settingsManager,
                        locationManager: locationManager)
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
                case .active:
                    workoutManager.appActive()
                case .inactive:
                    workoutManager.appInactive()
                case .background:
                    workoutManager.appBackground()
                default:
                    print(">> do something else in future")
            }
        }
    }
}
