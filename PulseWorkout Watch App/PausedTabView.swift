//
//  PausedTabView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 23/12/2022.
//

import Foundation
import WatchKit
import SwiftUI

struct PausedTabView: View {

    enum Tab {
        case paused, nowPlaying, help
    }

    @ObservedObject var workoutManager: WorkoutManager

    @State private var selection: Tab = .paused
    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }


    var body: some View {
        TabView(selection: $selection) {

            PausedView(workoutManager: workoutManager)
                .tag(Tab.paused)
            
            NowPlayingView()
                .tag(Tab.nowPlaying)
            
            HelpView()
                .tag(Tab.help)
            
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
    }
}

struct PausedTabView_Previews: PreviewProvider {
    static var workoutManager = WorkoutManager()

    static var previews: some View {
        PausedTabView(workoutManager: workoutManager)
    }
}

