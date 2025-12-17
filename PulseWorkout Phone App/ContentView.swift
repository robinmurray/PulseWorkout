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
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var bluetoothManager: BTDevicesController
    @ObservedObject var settingsManager: SettingsManager = SettingsManager.shared
    
    var body: some View {
        TabView(selection: $navigationCoordinator.selectedTab) {
            
            NavigationStack(path: $navigationCoordinator.homePath) {
                ActivityHistoryView(navigationCoordinator: navigationCoordinator)
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(ContentViewTab.home)
            
            NavigationStack(path: $navigationCoordinator.newActivityPath) {
                StartView(navigationCoordinator: navigationCoordinator,
                          liveActivityManager: liveActivityManager,
                          profileManager: profileManager)
            }
            .tabItem {
                Label("New Activity", systemImage: "figure.run")
            }
            .tag(ContentViewTab.newActivity)
            
            NavigationStack(path: $navigationCoordinator.statsPath) {
                StatisticsView(navigationCoordinator: navigationCoordinator)
            }
            .tabItem {
                Label("Stats", systemImage: "chart.line.text.clipboard")
            }
            .tag(ContentViewTab.stats)

            NavigationStack(path: $navigationCoordinator.settingsPath) {
                SettingsView(navigationCoordinator: navigationCoordinator,
                             bluetoothManager: bluetoothManager)
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

    let locationManager = LocationManager()
    let profileManager = ProfileManager()
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                  bluetoothManager: bluetoothManager)
    let navigationCoordinator = NavigationCoordinator()
    
    ContentView(navigationCoordinator: navigationCoordinator,
                liveActivityManager: liveActivityManager,
                profileManager: profileManager,
                locationManager: locationManager,
                bluetoothManager: bluetoothManager)
}
