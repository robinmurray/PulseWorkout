//
//  StartTabView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import Foundation
import SwiftUI
import WatchKit

struct StartTabView: View {

    enum Tab {
        case start, summaryMetrics, nowPlaying, btDevices
    }

    @ObservedObject var workoutManager: WorkoutManager
    @ObservedObject var profileManager: ActivityProfiles
    @State private var selection: Tab = .start
    
    
    init(workoutManager: WorkoutManager, profileManager: ActivityProfiles) {
        self.workoutManager = workoutManager
        self.profileManager = profileManager
    }

    var body: some View {
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

struct StartTabView_Previews: PreviewProvider {
    static var workoutManager = WorkoutManager()
    static var profileManager = ActivityProfiles()

    static var previews: some View {
        StartTabView(workoutManager: workoutManager,
                     profileManager: profileManager)
    }
}
