//
//  StartView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//


import Foundation


import SwiftUI


struct StartView: View {

    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var profileManager: ActivityProfiles
    @ObservedObject var activityDataManager: ActivityDataManager

    
    var body: some View {
        VStack {
            ProfileListView(profileManager: profileManager,
                            liveActivityManager: liveActivityManager,
                            activityDataManager: activityDataManager)

            BTDeviceBarView(liveActivityManager: liveActivityManager)

            }
            .padding(.horizontal)
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.inline)
        }
    }


struct StartView_Previews: PreviewProvider {
    static var settingsManager = SettingsManager()
    static var activityDataManager = ActivityDataManager(settingsManager: settingsManager)
    static var locationManager = LocationManager(activityDataManager: activityDataManager, settingsManager: settingsManager)

    static var liveActivityManager = LiveActivityManager(locationManager: locationManager, activityDataManager: activityDataManager,
        settingsManager: settingsManager)
    static var profileManager = ActivityProfiles()

    static var previews: some View {
        StartView(liveActivityManager: liveActivityManager,
                  profileManager: profileManager,
                  activityDataManager: activityDataManager)
    }
}
