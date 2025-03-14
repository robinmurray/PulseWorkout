//
//  ActivitySaveView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 24/08/2023.
//

import SwiftUI




struct ActivitySaveView: View {
   
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var dataCache: DataCache
    
    enum NavigationTarget {
        case ActivityDetailView
    }

    
    var body: some View {
        VStack(alignment: .leading) {

            ActivityHeaderView(activityRecord: liveActivityManager.liveActivityRecord ??
                               ActivityRecord())
            Divider()
            
            Button {
                navigationCoordinator.goToView(targetView: NavigationTarget.ActivityDetailView)
            } label: {
                Text("Summary")
            }
            
            Button(action: {navigationCoordinator.home()}) {
                Text("Done").padding([.leading, .trailing], 40)

            }
            .buttonStyle(.borderedProminent)
            .tint(Color.blue)
            


        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(for: NavigationTarget.self) { pathValue in
            
            if pathValue == .ActivityDetailView {

                ActivityDetailView(
                    navigationCoordinator: navigationCoordinator,
                    activityRecord: liveActivityManager.liveActivityRecord ??
                                                ActivityRecord(),
                    dataCache: dataCache)
            }

        }
 
    }
    
}

struct ActivitySaveView_Previews: PreviewProvider {
    static var navigationCoordinator = NavigationCoordinator()
    static var settingsManager = SettingsManager.shared
    static var record = ActivityRecord()
    static var locationManager = LocationManager()
    static var dataCache = DataCache()
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         dataCache: dataCache)
    

    static var previews: some View {
        ActivitySaveView(navigationCoordinator: navigationCoordinator,
                         liveActivityManager: liveActivityManager,
                         dataCache: dataCache)
    }
}
