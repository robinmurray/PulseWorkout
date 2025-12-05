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
    @ObservedObject var locationManager: LocationManager

    @ObservedObject var settingsManager: SettingsManager = SettingsManager.shared

    
    var body: some View {
        NavigationStack(path: $navigationCoordinator.path) {
            StartView(navigationCoordinator: navigationCoordinator,
                      liveActivityManager: liveActivityManager,
                      profileManager: profileManager)

        }
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
        .onAppear(perform: liveActivityManager.requestAuthorization)

    }

}

struct ContentView_Previews: PreviewProvider {
    static var navigationCoordinator = NavigationCoordinator()
    static var locationManager = LocationManager()
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager)
    static var profileManager = ProfileManager()

    
    static var previews: some View {
        ContentView(navigationCoordinator: navigationCoordinator,
                    liveActivityManager: liveActivityManager,
                    profileManager: profileManager,
                    locationManager: locationManager)
    }
}
