//
//  ContentView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import SwiftUI


enum AppState {
    case initial, live, paused, summary, discoverDevices
}

struct ContentView: View {

    @ObservedObject var workoutManager: WorkoutManager
    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }

    var body: some View {
        
        containedView()
    }
        
    func containedView() -> AnyView {
        
        switch workoutManager.appState {
            
        case .initial:
            return AnyView(StartTabView(workoutManager: workoutManager))
            
        case .live:
            return AnyView(LiveTabView(workoutManager: workoutManager)
                )
            
        case .paused:
            return AnyView(PausedTabView(workoutManager: workoutManager))
            
        case .summary:
            return AnyView(SummaryTabView(workoutManager: workoutManager))

        case .discoverDevices:
            return AnyView(BTDeviceDiscoverView(workoutManager: workoutManager))

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var workoutManager = WorkoutManager()

    static var previews: some View {
        ContentView(workoutManager: workoutManager)
    }
}
