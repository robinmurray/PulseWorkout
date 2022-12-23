//
//  PulseWorkoutApp.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import SwiftUI

@main
struct PulseWorkout_Watch_AppApp: App {
    
    @StateObject var workoutManager = WorkoutManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
            .environmentObject(workoutManager)
        }
    }
}
