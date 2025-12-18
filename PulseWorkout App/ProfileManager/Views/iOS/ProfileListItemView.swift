//
//  ProfileListItemView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 26/11/2024.
//

import SwiftUI
import HealthKit


struct ProfileListItemView: View {
    
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @Binding var profile: ActivityProfile
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var liveActivityManager: LiveActivityManager
    
    var body: some View {
        HStack {
            HStack {
                if #available(iOS 26.0, *) {
                    Button {
                        liveActivityManager.startWorkout(activityProfile: profile)
                        // Set last used date on profile and save to user defaults
                        // Do this after starting workout as may change list binding!!
                        profileManager.update(activityProfile: profile, onlyIfChanged: false)
                        
                        navigationCoordinator.selectedProfile = profile
                        navigationCoordinator.goToView(targetView: ProfileListView.NavigationTarget.LiveMetricsView)
                        
                    } label: {
                        HStack{
                            Image(systemName: HKWorkoutActivityType( rawValue: profile.workoutTypeId )!.iconImage)
                            
                            Text(profile.name)
                        
                        }
                    }
                    .buttonStyle(.glass)
                    .glassEffect(.regular)
                } else {
                    // Fallback on earlier versions
                    Button {
                        liveActivityManager.startWorkout(activityProfile: profile)
                        // Set last used date on profile and save to user defaults
                        // Do this after starting workout as may change list binding!!
                        profileManager.update(activityProfile: profile, onlyIfChanged: false)
                        
                        navigationCoordinator.selectedProfile = profile
                        navigationCoordinator.goToView(targetView: ProfileListView.NavigationTarget.LiveMetricsView)
                        
                    } label: {
                        HStack{
                            Image(systemName: HKWorkoutActivityType( rawValue: profile.workoutTypeId )!.iconImage)
                            
                            Text(profile.name)
                        
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                
                Spacer()
                
            }
            .foregroundStyle(.orange)
            .font(.title3)
            
            Spacer()
            
            HStack {
                if #available(iOS 26.0, *) {
                    Button {
                        navigationCoordinator.selectedProfile = profile
                        navigationCoordinator.goToView(targetView: ProfileListView.NavigationTarget.ProfileDetailView)
                        
                    } label: {
                        HStack{
                            Image(systemName: "square.and.pencil")
                                .background(Color.clear)
                                .clipShape(Circle())
                                .buttonStyle(PlainButtonStyle())
                            Text("Edit")
                        }
                        .foregroundColor(Color.blue)
                        
                    }
                    .buttonStyle(.glass)
                    .glassEffect(.regular)
                } else {
                    // Fallback on earlier versions
                    Button {
                        navigationCoordinator.selectedProfile = profile
                        navigationCoordinator.goToView(targetView: ProfileListView.NavigationTarget.ProfileDetailView)
                        
                    } label: {
                        HStack{
                            Image(systemName: "square.and.pencil")
                                .background(Color.clear)
                                .clipShape(Circle())
                                .buttonStyle(PlainButtonStyle())
                            Text("Edit")
                        }
                        .foregroundColor(Color.blue)
                        
                    }
                    .tint(Color.blue)
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
        .swipeActions {
            Button(role:.destructive) {
                profileManager.remove(activityProfile: profile)
            } label: {
                Label("Delete", systemImage: "xmark.bin")
            }
        }

    }
}

#Preview {
    let navigationCoordinator = NavigationCoordinator()
    let locationManager = LocationManager()
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                  bluetoothManager: bluetoothManager)
    let profileManager = ProfileManager()
    
    
    ProfileListItemView(navigationCoordinator: navigationCoordinator,
                        profile: .constant(profileManager.profiles[0]),
                       profileManager: profileManager,
                       liveActivityManager: liveActivityManager)
        
}
