//
//  LiveTabView.swift
//  PulsePace Watch App
//
//  Created by Robin Murray on 18/12/2022.
//

//import Foundation
import SwiftUI
import WatchKit

enum LiveScreenTab {
    case stop, liveMetrics, nowPlaying
}

struct LiveTabView: View {
    
    @Binding var profile: ActivityProfile
    @ObservedObject var workoutManager: WorkoutManager

    func startWorkout() {
        workoutManager.startWorkout(activityProfile: profile)
    }
    var body: some View {

            TabView(selection: $workoutManager.liveTabSelection) {
                
                StopView(workoutManager: workoutManager)
                    .tag(LiveScreenTab.stop)
                
                LiveMetricsView(workoutManager: workoutManager)
                    .tag(LiveScreenTab.liveMetrics)
                
                
                NowPlayingView()
                    .tag(LiveScreenTab.nowPlaying)
                
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .automatic))
            .navigationBarBackButtonHidden(true)
//            .onAppear(perform: startWorkout)
            .navigationTitle(profile.name)

    }
    
}
    



/*
struct LiveTabView_Previews: PreviewProvider {
    
    static var workoutManager = WorkoutManager()

    static var previews: some View {
        LiveTabView(workoutManager: workoutManager)
    }
}
*/
