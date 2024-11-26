//
//  ProfileListItemView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 13/04/2023.
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
            VStack {

                    HStack {
                        Button {
                            navigationCoordinator.selectedProfile = profile
                            navigationCoordinator.goToView(targetView: ProfileListView.NavigationTarget.ProfileDetailView)
                        } label: {
                            VStack{
                                Image(systemName: "square.and.pencil")
                                    .foregroundColor(Color.blue)
                                    .background(Color.clear)
                                    .clipShape(Circle())
                                    .buttonStyle(PlainButtonStyle())
                            }
                            
                        }
                        .tint(Color.blue)
                        .buttonStyle(BorderlessButtonStyle())

                        Button {
                            navigationCoordinator.selectedProfile = profile
                            liveActivityManager.startWorkout(activityProfile: profile)
                            
                            // Set last used date on profile and save to user defaults
                            // Do this after starting workout as may change list binding!!
                            profileManager.update(activityProfile: profile, onlyIfChanged: false)
                            
                            navigationCoordinator.goToView(targetView: ProfileListView.NavigationTarget.LiveTabView)
                        } label: {
                            HStack{
                                
                                Text(profile.name)
                                    .foregroundStyle(.orange)
                                
                                Spacer()
                                
                                Image(systemName: HKWorkoutActivityType( rawValue: profile.workoutTypeId )!.iconImage)
                                    .foregroundColor(Color.orange)
                                
                            }
                            
                        }
                        .tint(Color.green)
                        .buttonStyle(BorderlessButtonStyle())

                    }
                    
            }
                
        }

    }

}
    
    
    
     struct ProfileListItemView_Previews: PreviewProvider {
     
         static var navigationCoordinator = NavigationCoordinator()
         static var settingsManager = SettingsManager()
         static var dataCache = DataCache(settingsManager: settingsManager)
         static var locationManager = LocationManager(settingsManager: settingsManager)
         static var bluetoothManager = BTDevicesController(requestedServices: nil)
         static var liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                              bluetoothManager: bluetoothManager,
                                                              settingsManager: settingsManager,
                                                              dataCache: dataCache)
         static var profileManager = ProfileManager()

         
         
         static var previews: some View {

             ProfileListItemView(navigationCoordinator: navigationCoordinator,
                                 profile: .constant(profileManager.profiles[0]),
                                profileManager: profileManager,
                                liveActivityManager: liveActivityManager,
                                dataCache: dataCache)
                 
         }
     }
     
    

