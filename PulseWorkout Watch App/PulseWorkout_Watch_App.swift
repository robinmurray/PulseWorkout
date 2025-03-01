//
//  PulseWorkoutApp.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import SwiftUI
import os

@main
struct PulseWorkout_Watch_App: App {
    @WKApplicationDelegateAdaptor var appDelegate: WatchAppDelegate
    @Environment(\.scenePhase) private var scenePhase

    
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var dataCache: DataCache
    @ObservedObject var bluetoothManager: BTDevicesController
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    var cloudKitNotificationManager: CloudKitNotificationManager
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "PulseWorkout_Watch_App")
    
    init() {
        let myCloudKitNotificationManager = CloudKitNotificationManager()
        let mySettingsManager = SettingsManager()
        let myLocationManager = LocationManager(settingsManager: mySettingsManager)
        let myDataCache = DataCache(settingsManager: mySettingsManager)
        let myBluetoothManager = BTDevicesController(requestedServices: nil)
        
        self.cloudKitNotificationManager = myCloudKitNotificationManager

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
        
        
        // Register notifications
        myDataCache.registerNotifications(notificationManager: myCloudKitNotificationManager)
        self.profileManager.registerNotifications(notificationManager: myCloudKitNotificationManager)
        
        // register datacache in app delegate so can perform cache updates
        appDelegate.notificationManager = myCloudKitNotificationManager
    }

    /// Manage change of Scene Phase
    /// On change to active connect bluetooth devices if workout not live (as then devices would already be connected)
    func appActive(oldScenePhase: ScenePhase) {
        logger.log("App becoming active")
        if (oldScenePhase == .background && (liveActivityManager.liveActivityState != .live)) {
            bluetoothManager.connectDevices()
        }
    }

    /// Manage change of Scene Phase
    /// On change to inactive connect bluetooth devices if workout not live (as then devices would already be connected)
    func appInactive(oldScenePhase: ScenePhase) {
        logger.log("App becoming Inactive")
        if (oldScenePhase == .background && (liveActivityManager.liveActivityState != .live)) {
            bluetoothManager.connectDevices()
        }
    }
    
    /// Manage change of Scene Phase
    /// On change to background disconnect bluetooth devices if workout not live
    func appBackground(oldScenePhase: ScenePhase) {
        logger.log("App becoming Background")
        if liveActivityManager.liveActivityState != .live {
            bluetoothManager.disconnectKnownDevices()
        }
    }
   
    
    
    var body: some Scene {
        WindowGroup {
            ContentView(navigationCoordinator: navigationCoordinator,
                        liveActivityManager: liveActivityManager,
                        profileManager: profileManager,
                        dataCache: dataCache,
                        settingsManager: settingsManager,
                        locationManager: locationManager)
        }
        .onChange(of: scenePhase) { oldScenePhase, newScenePhase in
            switch newScenePhase {
                case .active:
                    appActive(oldScenePhase: oldScenePhase)
                case .inactive:
                    appInactive(oldScenePhase: oldScenePhase)
                case .background:
                    appBackground(oldScenePhase: oldScenePhase)
                default:
                    print(">> do something else in future")
            }
        }
    }
}
