//
//  SummaryTabView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import Foundation
import WatchKit
import SwiftUI

struct SummaryTabView: View {

    enum Tab {
        case summaryMetrics, nowPlaying
    }

    @ObservedObject var workoutManager: WorkoutManager
    @State private var selection: Tab = .summaryMetrics
    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }


    var body: some View {
        TabView(selection: $selection) {

            SummaryMetricsView(workoutManager: workoutManager,
                               viewTitleText: "Summary Metrics",
                               displayDone: true,
                               metrics: workoutManager.summaryMetrics)
                .tag(Tab.summaryMetrics)

            
            NowPlayingView()
                .tag(Tab.nowPlaying)

        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
    }
}

struct SummaryTabView_Previews: PreviewProvider {
    static var workoutManager = WorkoutManager()

    static var previews: some View {
        SummaryTabView(workoutManager: workoutManager)
    }
}

