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
    
    @ObservedObject var workoutManager: WorkoutManager
    @ObservedObject var profileManager: ActivityProfiles
    @ObservedObject var activityDataManager: ActivityDataManager
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var locationManager: LocationManager
    
    @State private var selection: Tab = .start
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {

                StartView(workoutManager: workoutManager,
                          profileManager: profileManager,
                          activityDataManager: activityDataManager)
                    .tag(Tab.start)
                
                LocationView(locationManager: locationManager)

                ActivityHistoryView(activityDataManager: activityDataManager)
                    .tag(Tab.activityHistory)
                
                NowPlayingView().tag(Tab.nowPlaying)

                SettingsView(bluetoothManager: workoutManager.bluetoothManager!, settingsManager: settingsManager, activityDataManager: activityDataManager).tag(Tab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .automatic))
            .onAppear(perform: workoutManager.requestAuthorization)

        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var activityDataManager = ActivityDataManager()
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(activityDataManager: activityDataManager, settingsManager: settingsManager)
    static var workoutManager = WorkoutManager(locationManager: locationManager, activityDataManager: activityDataManager,
        settingsManager: settingsManager)
    static var profileManager = ActivityProfiles()

    
    static var previews: some View {
        ContentView(workoutManager: workoutManager, profileManager:             profileManager, activityDataManager: activityDataManager,
                    settingsManager: settingsManager,
                    locationManager: locationManager)
    }
}
