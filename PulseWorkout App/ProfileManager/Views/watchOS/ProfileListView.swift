//
//  ProfileListView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 14/04/2023.
//

import SwiftUI
import HealthKit

struct ProfileListView: View {

    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var liveActivityManager: LiveActivityManager
    
    enum NavigationTarget {
        case ProfileDetailView
        case LiveTabView
        case TopMenuView
        case NewProfileDetailView
        case ActivitySaveView
    }
    
    var body: some View {
        
        List {
        
            ForEach(profileManager.profiles) { profile in

                ProfileListItemView(
                    navigationCoordinator: navigationCoordinator,
                    profile:  self.$profileManager.profiles[self.profileManager.profiles.firstIndex(where: { $0.id == profile.id })!],
                    profileManager: profileManager,
                    liveActivityManager: liveActivityManager)

            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle {
            Label("Profiles", systemImage: "figure.run")
                .foregroundColor(.orange)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                HStack{

                    Button {
                        navigationCoordinator.goToView(targetView: NavigationTarget.TopMenuView)
                    } label: {
                        Label("Menu", systemImage: "list.triangle")
                    }

                    Button {
                        navigationCoordinator.goToView(targetView: NavigationTarget.NewProfileDetailView)
                    } label: {
                        Label("Add", systemImage: "plus")
                    }

                }

            }
        }
        .navigationDestination(for: NavigationTarget.self) { pathValue in

            if pathValue == .ProfileDetailView {

                ProfileDetailView(profileManager: profileManager,
                                  profile: self.$profileManager.profiles[self.profileManager.profiles.firstIndex(where: { $0.id == navigationCoordinator.selectedProfile!.id }) ?? 0] )
            }
            else if pathValue == .LiveTabView {
                
                LiveTabView(navigationCoordinator: navigationCoordinator,
                            profileName: navigationCoordinator.selectedProfile!.name,
                            liveActivityManager: liveActivityManager)
            }
            else if pathValue == .TopMenuView {

                TopMenuView( navigationCoordinator: navigationCoordinator,
                             profileManager: profileManager,
                             liveActivityManager: liveActivityManager)
            }
            else if pathValue == .NewProfileDetailView {
                
                NewProfileDetailView(profileManager: profileManager)
            } else if pathValue == .ActivitySaveView {
                
                ActivitySaveView(navigationCoordinator: navigationCoordinator,
                                 liveActivityManager: liveActivityManager)
            }
            
        }
    }
}



#Preview {

    let navigationCoordinator = NavigationCoordinator()
    let profileManager = ProfileManager()
    let locationManager = LocationManager()
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                  bluetoothManager: bluetoothManager)

    
    ProfileListView(navigationCoordinator: navigationCoordinator,
                    profileManager: profileManager,
                    liveActivityManager: liveActivityManager)
}
