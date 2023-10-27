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
    case stop, liveMetrics, location, nowPlaying
}

struct LiveTabView: View {
    
    var profileName: String
    @ObservedObject var workoutManager: WorkoutManager
    @ObservedObject var activityDataManager: ActivityDataManager

    var body: some View {

            TabView(selection: $workoutManager.liveTabSelection) {
                
                StopView(workoutManager: workoutManager)
                    .tag(LiveScreenTab.stop)
                
                LiveMetricsView(workoutManager: workoutManager)
                    .tag(LiveScreenTab.liveMetrics)
                
                LocationView(locationManager: workoutManager.locationManager)
                    .tag(LiveScreenTab.location)


                NowPlayingView()
                    .tag(LiveScreenTab.nowPlaying)
                
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .automatic))
            .navigationBarBackButtonHidden(true)
            .navigationTitle(profileName)

    }
    
}
    




struct LiveTabView_Previews: PreviewProvider {
    
    static var activityDataManager = ActivityDataManager()
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(activityDataManager: activityDataManager, settingsManager: settingsManager)

    static var workoutManager = WorkoutManager(locationManager: locationManager, activityDataManager: activityDataManager,
        settingsManager: settingsManager)

    static var previews: some View {
        LiveTabView(profileName: "Preview Profile", workoutManager: workoutManager, activityDataManager: activityDataManager)
    }
}

