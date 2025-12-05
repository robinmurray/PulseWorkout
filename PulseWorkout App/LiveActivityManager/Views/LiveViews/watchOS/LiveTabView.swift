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
    
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    var profileName: String
    @ObservedObject var liveActivityManager: LiveActivityManager

    var body: some View {

            TabView(selection: $liveActivityManager.liveTabSelection) {
                
                StopView(navigationCoordinator: navigationCoordinator,
                         liveActivityManager: liveActivityManager)
                    .tag(LiveScreenTab.stop)
                    .navigationTitle("Stop")
                
                LiveMetricsView(navigationCoordinator: navigationCoordinator,
                                liveActivityManager: liveActivityManager)
                    .tag(LiveScreenTab.liveMetrics)
                    .navigationTitle {
                        Label(profileName, 
                              systemImage: HKWorkoutActivityType( rawValue: liveActivityManager.liveActivityProfile!.workoutTypeId)!.iconImage )
                        .foregroundColor(.orange)
                    }


                LocationView(navigationCoordinator: navigationCoordinator,
                             locationManager: liveActivityManager.locationManager)
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
    
    static var navigationCoordinator = NavigationCoordinator()
    static var locationManager = LocationManager()
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager)

    static var previews: some View {
        LiveTabView(navigationCoordinator: navigationCoordinator,
                    profileName: "Preview Profile",
                    liveActivityManager: liveActivityManager)
    }
}

