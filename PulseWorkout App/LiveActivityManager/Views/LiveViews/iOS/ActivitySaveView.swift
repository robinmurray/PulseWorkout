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

    
    var body: some View {
        VStack(alignment: .leading) {
            
            ScrollView {
                ActivityDetailView(navigationCoordinator: navigationCoordinator,
                                   activityRecord: liveActivityManager.liveActivityRecord ??
                                   ActivityRecord())
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
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                  bluetoothManager: bluetoothManager)
    
    ActivitySaveView(navigationCoordinator: navigationCoordinator,
                     liveActivityManager: liveActivityManager)
}
