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

    
    var body: some View {
        VStack(alignment: .leading) {
            
            ScrollView {
                ActivityDetailView(navigationCoordinator: navigationCoordinator,
                                   activityRecord: liveActivityManager.liveActivityRecord ??
                                   ActivityRecord(settingsManager: liveActivityManager.settingsManager), dataCache: dataCache)
            }

            Spacer()
            HStack {
                Spacer()
                Button(action: {
                        navigationCoordinator.home()
                    }
                )
                {
                    Text("Done").padding([.leading, .trailing], 40)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.blue)
                Spacer()
            }

        }
        .navigationBarBackButtonHidden(true)

    }
    
}

#Preview {

    @Previewable @State var newProfile: ActivityProfile = ProfileManager().newProfile()

    let navigationCoordinator = NavigationCoordinator()
    let settingsManager = SettingsManager()
    let locationManager = LocationManager(settingsManager: settingsManager)
    let dataCache = DataCache(settingsManager: settingsManager)
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         settingsManager: settingsManager,
                                                         dataCache: dataCache)
    
    ActivitySaveView(navigationCoordinator: navigationCoordinator,
                     liveActivityManager: liveActivityManager,
                     dataCache: dataCache)
}
