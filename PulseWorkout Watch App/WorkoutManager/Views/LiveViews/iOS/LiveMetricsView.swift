//
//  LiveMetricsView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 18/11/2024.
//

import SwiftUI

struct LiveMetricsView: View {
    
    @ObservedObject var liveActivityManager: LiveActivityManager
    var activityData: ActivityRecord

    init(liveActivityManager: LiveActivityManager) {
        self.liveActivityManager = liveActivityManager
        self.activityData = liveActivityManager.liveActivityRecord ??
        ActivityRecord(settingsManager: liveActivityManager.settingsManager)
        
    }
    

    var body: some View {

        
        Text("Live Metrics!")
        
        
    }

}
  

#Preview {
    let activityProfile = ProfileManager()
    let settingsManager = SettingsManager()
    let locationManager = LocationManager(settingsManager: settingsManager)
    let dataCache = DataCache(settingsManager: settingsManager)
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         settingsManager: settingsManager,
                                                         dataCache: dataCache)

    LiveMetricsView(liveActivityManager: liveActivityManager)
}
