//
//  StartView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//


import Foundation


import SwiftUI


struct StartView: View {
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var profileManager: ProfileManager

    
    var body: some View {
        
        if #available(iOS 26.0, watchOS 26.0, *) {
            ZStack {
                ProfileListView(navigationCoordinator: navigationCoordinator,
                                profileManager: profileManager,
                                liveActivityManager: liveActivityManager)
                
                VStack {
                    Spacer()
                    BTDeviceBarView(liveActivityManager: liveActivityManager)
                        .glassEffect(.clear)
                        .frame(height: 80)
                }
            }
            
            } else {
                // Fallback on earlier versions
                VStack {
                    ProfileListView(navigationCoordinator: navigationCoordinator,
                                    profileManager: profileManager,
                                    liveActivityManager: liveActivityManager)
                    
                    
                    BTDeviceBarView(liveActivityManager: liveActivityManager)
                }
            }

    }
}


struct StartView_Previews: PreviewProvider {

    static var locationManager = LocationManager()
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager)
    static var profileManager = ProfileManager()
    static var navigationCoordinator = NavigationCoordinator()

    static var previews: some View {
        StartView(navigationCoordinator: navigationCoordinator,
                  liveActivityManager: liveActivityManager,
                  profileManager: profileManager)
    }
}
