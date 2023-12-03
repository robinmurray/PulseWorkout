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
        case paused, nowPlaying
    }

    @ObservedObject var liveActivityManager: LiveActivityManager

    @State private var selection: Tab = .paused
    
    init(liveActivityManager: LiveActivityManager) {
        self.liveActivityManager = liveActivityManager
    }


    var body: some View {
        TabView(selection: $selection) {

            PausedView(liveActivityManager: liveActivityManager)
                .tag(Tab.paused)
            
            NowPlayingView()
                .tag(Tab.nowPlaying)
            
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
    }
}

struct PausedTabView_Previews: PreviewProvider {
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache()
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager, settingsManager: settingsManager,
        dataCache: dataCache)
    
    static var previews: some View {
        PausedTabView(liveActivityManager: liveActivityManager)
    }
}

