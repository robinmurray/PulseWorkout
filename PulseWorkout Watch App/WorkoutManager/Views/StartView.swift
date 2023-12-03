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
    @ObservedObject var dataCache: DataCache

    
    var body: some View {
        VStack {
            ProfileListView(profileManager: profileManager,
                            liveActivityManager: liveActivityManager,
                            dataCache: dataCache)

            BTDeviceBarView(liveActivityManager: liveActivityManager)

            }
            .padding(.horizontal)
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.inline)
        }
    }


struct StartView_Previews: PreviewProvider {
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache()
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager, settingsManager: settingsManager,
        dataCache: dataCache)
    static var profileManager = ActivityProfiles()

    static var previews: some View {
        StartView(liveActivityManager: liveActivityManager,
                  profileManager: profileManager,
                  dataCache: dataCache)
    }
}
