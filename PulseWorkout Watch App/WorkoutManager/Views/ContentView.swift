//
//  ContentView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import Foundation
import SwiftUI
import WatchKit


struct ContentView: View {

    enum Tab {
        case start, location, activityHistory, nowPlaying, settings
    }
    
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var profileManager: ActivityProfiles
    @ObservedObject var dataCache: DataCache
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var locationManager: LocationManager
    
    @State private var selection: Tab = .start
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {

                StartView(liveActivityManager: liveActivityManager,
                          profileManager: profileManager,
                          dataCache: dataCache)
                    .tag(Tab.start)
                
                LocationView(locationManager: locationManager)

                ActivityHistoryView(dataCache: dataCache)
                    .tag(Tab.activityHistory)
                
                NowPlayingView().tag(Tab.nowPlaying)

                SettingsView(bluetoothManager: liveActivityManager.bluetoothManager!, settingsManager: settingsManager).tag(Tab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .automatic))
            .onAppear(perform: liveActivityManager.requestAuthorization)

        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache()
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager, settingsManager: settingsManager,
        dataCache: dataCache)
    static var profileManager = ActivityProfiles()

    
    static var previews: some View {
        ContentView(liveActivityManager: liveActivityManager, profileManager:             profileManager, dataCache: dataCache,
                    settingsManager: settingsManager,
                    locationManager: locationManager)
    }
}
