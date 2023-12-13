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

    var body: some View {

            TabView(selection: $liveActivityManager.liveTabSelection) {
                
                StopView(liveActivityManager: liveActivityManager)
                    .tag(LiveScreenTab.stop)
                    .navigationTitle("Stop")
                
                LiveMetricsView(liveActivityManager: liveActivityManager)
                    .tag(LiveScreenTab.liveMetrics)
                    .navigationTitle(profileName)
                
                LocationView(locationManager: liveActivityManager.locationManager)
                    .tag(LiveScreenTab.location)
                    .navigationTitle("Location")

/*
                NowPlayingView()
                    .tag(LiveScreenTab.nowPlaying)
                    .navigationTitle("Now Playing")
*/
            }
            .tabViewStyle(.verticalPage)
//            .tabViewStyle(.page(indexDisplayMode: .always))
//            .indexViewStyle(.page(backgroundDisplayMode: .automatic))
            .navigationBarBackButtonHidden(true)
//            .navigationTitle(profileName)


    }
    
}
    




struct LiveTabView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache()
    
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager, settingsManager: settingsManager,
        dataCache: dataCache)

    static var previews: some View {
        LiveTabView(profileName: "Preview Profile", liveActivityManager: liveActivityManager)
    }
}

