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
        case workoutType, start, summaryMetrics, profile, nowPlaying, help, btDevices
    }

//    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var workoutManager: WorkoutManager
    @State private var selection: Tab = .start
    
    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }

    var body: some View {
        TabView(selection: $selection) {

            WorkoutSelectionView(workoutManager: workoutManager)
                .tag(Tab.workoutType)
            
            StartView(workoutManager: workoutManager)
                .tag(Tab.start)
            
            SummaryMetricsView(workoutManager: workoutManager,
                               viewTitleText: "Last Workout",
                               displayDone: false,
                               metrics: workoutManager.lastSummaryMetrics)
                .tag(Tab.summaryMetrics)

            ProfileView(workoutManager: workoutManager)
                .tag(Tab.profile)

            
            NowPlayingView().tag(Tab.nowPlaying)
            
            HelpView()
                .tag(Tab.help)

            DevicesView(workoutManager: workoutManager).tag(Tab.btDevices)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
        .onAppear(perform: workoutManager.requestAuthorization)

    }
}

struct StartTabView_Previews: PreviewProvider {
    static var workoutManager = WorkoutManager()

    static var previews: some View {
        StartTabView(workoutManager: workoutManager)
    }
}
