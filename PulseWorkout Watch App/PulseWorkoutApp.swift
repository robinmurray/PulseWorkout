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

    @ObservedObject var profileData = ProfileData()


    var body: some Scene {
        WindowGroup {
            NavigationView
            {
                ContentView(profileData: profileData)
            }

        }
        .onChange(of: scenePhase) { phase in
            switch phase {
                case .active:
                    print(">> your code here on scene become active")
                case .inactive:
                    print(">> your code here on scene become inactive")
                case .background:
                    print(">> your code here on scene go background")
                default:
                    print(">> do something else in future")
            }
        }
    }
}
