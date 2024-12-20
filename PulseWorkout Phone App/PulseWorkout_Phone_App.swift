//
//  PulseWorkout_Phone_App.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 29/10/2024.
//

import SwiftUI

@main
struct PulseWorkout_Phone_App: App {
    
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var dataCache: DataCache
    @ObservedObject var bluetoothManager: BTDevicesController
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    
    init() {
        let mySettingsManager = SettingsManager()
        let myLocationManager = LocationManager(settingsManager: mySettingsManager)
        let myDataCache = DataCache(settingsManager: mySettingsManager)
        let myBluetoothManager = BTDevicesController(requestedServices: nil)

        self.liveActivityManager = LiveActivityManager(locationManager: myLocationManager,
                                                       bluetoothManager: myBluetoothManager,
                                                       settingsManager: mySettingsManager,
                                                       dataCache: myDataCache)
        self.locationManager = myLocationManager
        self.profileManager = ProfileManager()
        self.settingsManager = mySettingsManager
        self.dataCache = myDataCache
        self.bluetoothManager = myBluetoothManager
        self.navigationCoordinator = NavigationCoordinator()
        
        // register datacache in app delegate so can perform cache updates
        appDelegate.dataCache = self.dataCache
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(navigationCoordinator: navigationCoordinator,
                        liveActivityManager: liveActivityManager,
                        profileManager: profileManager,
                        dataCache: dataCache,
                        settingsManager: settingsManager,
                        locationManager: locationManager,
                        bluetoothManager: bluetoothManager)
        }
    }
}
