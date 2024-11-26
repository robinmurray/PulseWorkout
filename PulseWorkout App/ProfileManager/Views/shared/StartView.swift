//
//  StartView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//


import Foundation


import SwiftUI


struct StartView: View {
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var dataCache: DataCache

    
    var body: some View {
        VStack {
            ProfileListView(navigationCoordinator: navigationCoordinator,
                            profileManager: profileManager,
                            liveActivityManager: liveActivityManager,
                            dataCache: dataCache)

            BTDeviceBarView(liveActivityManager: liveActivityManager)

            }

    }
}


struct StartView_Previews: PreviewProvider {
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache(settingsManager: settingsManager)
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         settingsManager: settingsManager,
                                                         dataCache: dataCache)
    static var profileManager = ProfileManager()
    static var navigationCoordinator = NavigationCoordinator()

    static var previews: some View {
        StartView(navigationCoordinator: navigationCoordinator,
                  liveActivityManager: liveActivityManager,
                  profileManager: profileManager,
                  dataCache: dataCache)
    }
}
