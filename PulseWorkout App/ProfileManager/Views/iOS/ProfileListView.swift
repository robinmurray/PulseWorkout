//
//  ProfileListView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 18/11/2024.
//

import SwiftUI
import HealthKit


struct ProfileListView: View {
    
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var dataCache: DataCache

    enum NavigationTarget {
        case LiveMetricsView
        case ProfileDetailView
        case NewProfileDetailView
    }
    
    
    var body: some View {
        VStack {

            List {
                ForEach(profileManager.profiles) { profile in

                    ProfileListItemView(
                        navigationCoordinator: navigationCoordinator,
                        profile:  self.$profileManager.profiles[self.profileManager.profiles.firstIndex(where: { $0.id == profile.id })!],
                        profileManager: profileManager,
                        liveActivityManager: liveActivityManager,
                        dataCache: dataCache)

                }
    
            }
            .navigationDestination(for: NavigationTarget.self) { pathValue in

                if pathValue == .LiveMetricsView {


                    LiveMetricsView(navigationCoordinator: navigationCoordinator,
                                    profile: self.$profileManager.profiles[self.profileManager.profiles.firstIndex(where: { $0.id == (navigationCoordinator.selectedProfile?.id ?? UUID()) }) ?? 0] ,
                                    liveActivityManager: liveActivityManager,
                                    dataCache: dataCache)
 
                }
                else if pathValue == .ProfileDetailView {
                    
                    ProfileDetailView(profileManager: profileManager,
                                      profile: self.$profileManager.profiles[self.profileManager.profiles.firstIndex(where: { $0.id == (navigationCoordinator.selectedProfile?.id ?? UUID()) }) ?? 0] )
                    


                }
                else if pathValue == .NewProfileDetailView {
                    NewProfileDetailView(profileManager: profileManager)
                }
                
            }
            .listStyle(.grouped)
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    HStack {
                        Button {
                            navigationCoordinator.goToView(targetView: NavigationTarget.NewProfileDetailView)

                        } label: {
                            Label("Add", systemImage: "plus")
                            
                        }
                        .foregroundStyle(Color.blue)
                        .buttonStyle(PlainButtonStyle())

                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    HStack {
                        Text("Activity Profiles")
                        Spacer()
                        Image(systemName: "figure.run")
                    }.foregroundColor(.orange)
                }
            }

            
            Spacer()
        }
    }
}


#Preview {
    
    let profileManager = ProfileManager()
    let locationManager = LocationManager()
    let dataCache = DataCache()
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                  bluetoothManager: bluetoothManager,
                                                  dataCache: dataCache)
    let navigationCoordinator = NavigationCoordinator()
    
    ProfileListView(navigationCoordinator: navigationCoordinator,
                    profileManager: profileManager,
                    liveActivityManager: liveActivityManager,
                    dataCache: dataCache)
}
