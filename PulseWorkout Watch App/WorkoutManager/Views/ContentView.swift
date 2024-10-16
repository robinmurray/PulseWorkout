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

    
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var dataCache: DataCache
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var locationManager: LocationManager

    
    var body: some View {
        NavigationStack {
            StartView(liveActivityManager: liveActivityManager,
                      profileManager: profileManager,
                      dataCache: dataCache)

        }
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
        .onAppear(perform: liveActivityManager.requestAuthorization)

    }

}

struct ContentView_Previews: PreviewProvider {
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache(settingsManager: settingsManager)
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         settingsManager: settingsManager,
                                                         dataCache: dataCache)
    static var profileManager = ProfileManager()

    
    static var previews: some View {
        ContentView(liveActivityManager: liveActivityManager,
                    profileManager: profileManager,
                    dataCache: dataCache,
                    settingsManager: settingsManager,
                    locationManager: locationManager)
    }
}
