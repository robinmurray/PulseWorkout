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
//    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var dataCache: DataCache
    @ObservedObject var bluetoothManager: BTDevicesController
    
    init() {
        let mySettingsManager = SettingsManager()
        let myLocationManager = LocationManager(settingsManager: mySettingsManager)
        let myDataCache = DataCache(settingsManager: mySettingsManager)
        
        self.locationManager = myLocationManager
        self.profileManager = ProfileManager()
        self.settingsManager = mySettingsManager
        self.dataCache = myDataCache
        self.bluetoothManager = BTDevicesController(requestedServices: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(profileManager: profileManager,
                        dataCache: dataCache,
                        settingsManager: settingsManager,
                        locationManager: locationManager,
                        bluetoothManager: bluetoothManager)
        }
    }
}
