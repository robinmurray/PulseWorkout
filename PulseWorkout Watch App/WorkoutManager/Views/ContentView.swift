//
//  ContentView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import Foundation
import SwiftUI
import WatchKit


enum AppState {
    case initial, live, paused, summary, inBluetooth
}

struct ContentView: View {

    enum Tab {
        case start, summaryMetrics, nowPlaying, btDevices
    }
    
    @ObservedObject var workoutManager: WorkoutManager
    @ObservedObject var profileManager: ActivityProfiles
    @State private var selection: Tab = .start
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {

                StartView(workoutManager: workoutManager,
                          profileManager: profileManager)
                    .tag(Tab.start)
                
                SummaryMetricsView(workoutManager: workoutManager,
                                   viewTitleText: "Last Workout",
                                   displayDone: false,
                                   metrics: workoutManager.lastSummaryMetrics)
                    .tag(Tab.summaryMetrics)

                NowPlayingView().tag(Tab.nowPlaying)

                BTContentView(bluetoothManager: workoutManager.bluetoothManager!).tag(Tab.btDevices)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .automatic))
            .onAppear(perform: workoutManager.requestAuthorization)

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
