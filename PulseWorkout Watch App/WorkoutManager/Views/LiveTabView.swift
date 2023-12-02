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
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var activityDataManager: ActivityDataManager

    var body: some View {

            TabView(selection: $liveActivityManager.liveTabSelection) {
                
                StopView(liveActivityManager: liveActivityManager)
                    .tag(LiveScreenTab.stop)
                
                LiveMetricsView(liveActivityManager: liveActivityManager)
                    .tag(LiveScreenTab.liveMetrics)
                
                LocationView(locationManager: liveActivityManager.locationManager)
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
    
    static var settingsManager = SettingsManager()
    static var activityDataManager = ActivityDataManager(settingsManager: settingsManager)
    static var locationManager = LocationManager(activityDataManager: activityDataManager, settingsManager: settingsManager)

    static var liveActivityManager = LiveActivityManager(locationManager: locationManager, activityDataManager: activityDataManager,
        settingsManager: settingsManager)

    static var previews: some View {
        LiveTabView(profileName: "Preview Profile", liveActivityManager: liveActivityManager, activityDataManager: activityDataManager)
    }
}

