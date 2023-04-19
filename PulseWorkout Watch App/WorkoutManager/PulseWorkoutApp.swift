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

    @ObservedObject var workoutManager = WorkoutManager()
    @ObservedObject var profileManager = ActivityProfiles()


    var body: some Scene {
        WindowGroup {
            ContentView(workoutManager: workoutManager,
                        profileManager: profileManager)
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
