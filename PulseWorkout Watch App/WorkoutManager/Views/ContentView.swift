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
        case start, activityHistory, nowPlaying, settings
    }
    
    @ObservedObject var workoutManager: WorkoutManager
    @ObservedObject var profileManager: ActivityProfiles
    @ObservedObject var activityDataManager: ActivityDataManager
    @ObservedObject var settingsManager: SettingsManager
    
    @State private var selection: Tab = .start
    
    var body: some View {
        NavigationStack {
            TabView(selection: $selection) {

                StartView(workoutManager: workoutManager,
                          profileManager: profileManager,
                          activityDataManager: activityDataManager)
                    .tag(Tab.start)

                ActivityHistoryView(activityDataManager: activityDataManager)
                    .tag(Tab.activityHistory)
                
                NowPlayingView().tag(Tab.nowPlaying)

                SettingsView(bluetoothManager: workoutManager.bluetoothManager!, settingsManager: settingsManager).tag(Tab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .automatic))
            .onAppear(perform: workoutManager.requestAuthorization)

        }
    }

}

struct ContentView_Previews: PreviewProvider {
    static var workoutManager = WorkoutManager()
    static var profileManager = ActivityProfiles()
    static var activityDataManager = ActivityDataManager()
    static var settingsManager = SettingsManager()

    static var previews: some View {
        ContentView(workoutManager: workoutManager, profileManager:         profileManager, activityDataManager: activityDataManager,
                    settingsManager: settingsManager)
    }
}
