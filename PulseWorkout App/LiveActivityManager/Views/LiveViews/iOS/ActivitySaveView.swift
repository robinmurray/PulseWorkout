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
                                   ActivityRecord(), dataCache: dataCache)
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
    let locationManager = LocationManager()
    let dataCache = DataCache()
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                  bluetoothManager: bluetoothManager,
                                                  dataCache: dataCache)
    
    ActivitySaveView(navigationCoordinator: navigationCoordinator,
                     liveActivityManager: liveActivityManager,
                     dataCache: dataCache)
}
