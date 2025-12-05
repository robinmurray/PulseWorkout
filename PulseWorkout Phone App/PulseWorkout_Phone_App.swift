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
    @ObservedObject var settingsManager: SettingsManager = SettingsManager.shared
    @ObservedObject var dataCache: DataCache = DataCache.shared
    @ObservedObject var bluetoothManager: BTDevicesController
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    var cloudKitNotificationManager: CloudKitNotificationManager
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    
    init() {

//        let myDataCache = DataCache()
        let myCloudKitNotificationManager = CloudKitNotificationManager()
        let myLocationManager = LocationManager()
//        let myDataCache = DataCache.shared
        let myBluetoothManager = BTDevicesController(requestedServices: nil)

        self.cloudKitNotificationManager = myCloudKitNotificationManager

        self.liveActivityManager = LiveActivityManager(locationManager: myLocationManager,
                                                       bluetoothManager: myBluetoothManager)
        self.profileManager = ProfileManager()

        self.locationManager = myLocationManager
//        self.dataCache = myDataCache
        self.bluetoothManager = myBluetoothManager
        self.navigationCoordinator = NavigationCoordinator()
        
        
        // Register notifications
        DataCache.shared.registerNotifications(notificationManager: myCloudKitNotificationManager)
        self.profileManager.registerNotifications(notificationManager: myCloudKitNotificationManager)
        SettingsManager.shared.registerNotifications(notificationManager: myCloudKitNotificationManager)
        
        // register datacache in app delegate so can perform cache updates
        appDelegate.notificationManager = myCloudKitNotificationManager
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(navigationCoordinator: navigationCoordinator,
                        liveActivityManager: liveActivityManager,
                        profileManager: profileManager,
                        locationManager: locationManager,
                        bluetoothManager: bluetoothManager)
        }
    }
}
