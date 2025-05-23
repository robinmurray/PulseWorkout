//
//  LiveAlwaysOnView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 05/09/2024.
//

import SwiftUI
import HealthKit

struct LiveAlwaysOnView: View {
    @ObservedObject var liveActivityManager: LiveActivityManager
    var contextDate: Date
    

    var body: some View {
        VStack {

            Spacer()
            Label("Always on view", systemImage: HKWorkoutActivityType( rawValue: liveActivityManager.liveActivityProfile!.workoutTypeId)!.iconImage)
                .labelStyle(.iconOnly)
                .font(.largeTitle)
                .foregroundStyle(.green)
            
            ElapsedTimeView(elapsedTime: liveActivityManager.movingTime(at: contextDate),
                            showSeconds: false,
                            showSubseconds: false)
                .foregroundStyle(.green)
                .font(.largeTitle)
            
            Spacer()
                
        }

    }
}


struct LiveAlwaysOnView_Previews: PreviewProvider {
    
    static var activityProfile = ProfileManager()
    static var locationManager = LocationManager()
    static var dataCache = DataCache()
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         dataCache: dataCache)

    
    static var previews: some View {
        LiveAlwaysOnView(liveActivityManager: liveActivityManager, contextDate: Date())
    }
}
