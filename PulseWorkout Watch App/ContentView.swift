//
//  ContentView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import Foundation
import SwiftUI


struct ContentView: View {

    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var dataCache: DataCache
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var locationManager: LocationManager

    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.path) {
            StartView(navigationCoordinator: navigationCoordinator,
                      liveActivityManager: liveActivityManager,
                      profileManager: profileManager,
                      dataCache: dataCache)

        }
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
        .onAppear(perform: liveActivityManager.requestAuthorization)

    }

}

struct ContentView_Previews: PreviewProvider {
    static var navigationCoordinator = NavigationCoordinator()
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
        ContentView(navigationCoordinator: navigationCoordinator,
                    liveActivityManager: liveActivityManager,
                    profileManager: profileManager,
                    dataCache: dataCache,
                    settingsManager: settingsManager,
                    locationManager: locationManager)
    }
}
