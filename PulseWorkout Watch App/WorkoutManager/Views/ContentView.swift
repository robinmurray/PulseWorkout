//
//  ContentView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import SwiftUI


enum AppState {
    case initial, live, paused, summary, inBluetooth
}

struct ContentView: View {

    @ObservedObject var workoutManager: WorkoutManager
    @ObservedObject var profileManager: ActivityProfiles
    
    init(workoutManager: WorkoutManager, profileManager: ActivityProfiles) {
        self.profileManager = profileManager
        self.workoutManager = workoutManager

    }

    var body: some View {
        
        containedView()
    }
        
    func containedView() -> AnyView {
        
        switch workoutManager.appState {
            
        case .initial:
            return AnyView(StartTabView(workoutManager: workoutManager,
                                        profileManager: profileManager))
            
        case .live:
            return AnyView(LiveTabView(workoutManager: workoutManager)
                )
            
        case .paused:
            return AnyView(PausedTabView(workoutManager: workoutManager))
            
        case .summary:
            return AnyView(SummaryTabView(workoutManager: workoutManager))

        case .inBluetooth:
            return AnyView(BTContentView(bluetoothManager:  workoutManager.bluetoothManager!))

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var workoutManager = WorkoutManager()
    static var profileManager = ActivityProfiles()

    static var previews: some View {
        ContentView(workoutManager: workoutManager, profileManager: profileManager)
    }
}
