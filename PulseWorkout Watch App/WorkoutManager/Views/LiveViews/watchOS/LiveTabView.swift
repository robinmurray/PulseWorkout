//
//  LiveTabView.swift
//  PulsePace Watch App
//
//  Created by Robin Murray on 18/12/2022.
//

//import Foundation
import SwiftUI
import WatchKit
import HealthKit

enum LiveScreenTab {
    case stop, liveMetrics, location, nowPlaying
}

struct LiveTabView: View {
    
    var profileName: String
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var dataCache: DataCache

    var body: some View {

            TabView(selection: $liveActivityManager.liveTabSelection) {
                
                StopView(liveActivityManager: liveActivityManager, dataCache: dataCache)
                    .tag(LiveScreenTab.stop)
                    .navigationTitle("Stop")
                
                LiveMetricsView(liveActivityManager: liveActivityManager)
                    .tag(LiveScreenTab.liveMetrics)
                    .navigationTitle {
                        Label(profileName, 
                              systemImage: HKWorkoutActivityType( rawValue: liveActivityManager.liveActivityProfile!.workoutTypeId)!.iconImage )
                        .foregroundColor(.orange)
                    }


                LocationView(locationManager: liveActivityManager.locationManager)
                    .tag(LiveScreenTab.location)
                    .navigationTitle("Location")

/*
                NowPlayingView()
                    .tag(LiveScreenTab.nowPlaying)
                    .navigationTitle("Now Playing")
*/
            }
            .tabViewStyle(.verticalPage)
//            .tabViewStyle(.page(indexDisplayMode: .always))
//            .indexViewStyle(.page(backgroundDisplayMode: .automatic))
            .navigationBarBackButtonHidden(true)
//            .navigationTitle(profileName)


    }
    
}
    




struct LiveTabView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache(settingsManager: settingsManager)
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         settingsManager: settingsManager,
                                                         dataCache: dataCache)

    static var previews: some View {
        LiveTabView(profileName: "Preview Profile",
                    liveActivityManager: liveActivityManager,
                    dataCache: dataCache)
    }
}

