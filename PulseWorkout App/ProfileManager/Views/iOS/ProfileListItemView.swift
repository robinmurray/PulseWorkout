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
    @ObservedObject var dataCache: DataCache
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    HStack {
                        Image(systemName: HKWorkoutActivityType( rawValue: profile.workoutTypeId )!.iconImage)
                        
                        Text(profile.name)
                        
                        Spacer()
                        
                    }
                    .foregroundStyle(.orange)
                    .font(.title3)
                    
                    HStack {
                        HStack {
                            Image(systemName: "arrow.down.heart.fill")
                            Text(profile.loLimitAlarmActive ? String(profile.loLimitAlarm) : "___")
                        }.foregroundStyle(profile.loLimitAlarmActive ? .red : .gray)
                        HStack {
                            Image(systemName: "arrow.up.heart.fill")
                            Text(profile.hiLimitAlarmActive ? String(profile.hiLimitAlarm) : "___")
                        }.foregroundStyle(profile.hiLimitAlarmActive ? .red : .gray)
                        
                        Spacer()
                    }
                    .foregroundStyle(.red)
                    
                }
                
                Spacer()
                Button {
                    liveActivityManager.startWorkout(activityProfile: profile)
                    // Set last used date on profile and save to user defaults
                    // Do this after starting workout as may change list binding!!
                    profileManager.update(activityProfile: profile, onlyIfChanged: false)
                    
                    navigationCoordinator.selectedProfile = profile
                    navigationCoordinator.goToView(targetView: ProfileListView.NavigationTarget.LiveMetricsView)

                } label: {
                    HStack{
                        Text("Start").font(.title)
                        Image(systemName: "play.circle").font(.title)
                        
                    }
                    
                }
                .tint(Color.green)
                .buttonStyle(.bordered)
                

            }

            HStack {
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

                Spacer()
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
    let settingsManager = SettingsManager()
    let dataCache = DataCache(settingsManager: settingsManager)
    let locationManager = LocationManager(settingsManager: settingsManager)
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         settingsManager: settingsManager,
                                                         dataCache: dataCache)
    let profileManager = ProfileManager()
    
    
    ProfileListItemView(navigationCoordinator: navigationCoordinator,
                        profile: .constant(profileManager.profiles[0]),
                       profileManager: profileManager,
                       liveActivityManager: liveActivityManager,
                       dataCache: dataCache)
        
}
