//
//  ContentView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 29/10/2024.
//

import SwiftUI


struct ContentView: View {
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var dataCache: DataCache
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var bluetoothManager: BTDevicesController
    
    var body: some View {
        TabView(selection: $navigationCoordinator.selectedTab) {
            
            NavigationStack(path: $navigationCoordinator.homePath) {
                ActivityHistoryView(navigationCoordinator: navigationCoordinator,
                                    dataCache: dataCache)
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(ContentViewTab.home)
            
            NavigationStack(path: $navigationCoordinator.newActivityPath) {
                StartView(navigationCoordinator: navigationCoordinator,
                          liveActivityManager: liveActivityManager,
                          profileManager: profileManager,
                          dataCache: dataCache)
            }
            .tabItem {
                Label("New Activity", systemImage: "figure.run")
            }
            .tag(ContentViewTab.newActivity)
            
            NavigationStack(path: $navigationCoordinator.statsPath) {
                StatisticsView(navigationCoordinator: navigationCoordinator,
                               profileManager: profileManager,
                               liveActivityManager: liveActivityManager,
                               dataCache: dataCache)
            }
            .tabItem {
                Label("Stats", systemImage: "person")
            }
            .tag(ContentViewTab.stats)

            NavigationStack(path: $navigationCoordinator.settingsPath) {
                SettingsView(navigationCoordinator: navigationCoordinator,
                             bluetoothManager: bluetoothManager,
                             settingsManager: settingsManager)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(ContentViewTab.settings)

        }
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .onAppear(perform: liveActivityManager.requestAuthorization)

    }

}



#Preview {

    let settingsManager = SettingsManager()
    let locationManager = LocationManager(settingsManager: settingsManager)
    let dataCache = DataCache(settingsManager: settingsManager)
    let profileManager = ProfileManager()
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                  bluetoothManager: bluetoothManager,
                                                  settingsManager: settingsManager,
                                                  dataCache: dataCache)
    let navigationCoordinator = NavigationCoordinator()
    
    ContentView(navigationCoordinator: navigationCoordinator,
                liveActivityManager: liveActivityManager,
                profileManager: profileManager,
                dataCache: dataCache,
                settingsManager: settingsManager,
                locationManager: locationManager,
                bluetoothManager: bluetoothManager)
}
