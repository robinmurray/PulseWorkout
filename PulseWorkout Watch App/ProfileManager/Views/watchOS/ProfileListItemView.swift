//
//  ProfileListItemView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 13/04/2023.
//

import SwiftUI
import HealthKit


struct ProfileListItemView: View {
    
    @Binding var profile: ActivityProfile
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var dataCache: DataCache

    @State private var navigateToDetailView : Bool = false
    @State private var navigateToLiveView : Bool = false
    
    // set navigation flags to false when view appears.
    // this allows view to reappear and navigation to work successfully!
    func resetNavigationFlags() {
        navigateToDetailView = false
        navigateToLiveView = false
    }
    
    var body: some View {
        VStack {
            NavigationStack {
                HStack {
                    Button {
                        navigateToDetailView = true
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
                    .navigationDestination(isPresented: $navigateToDetailView) {
                        ProfileDetailView(profileManager: profileManager,
                                          profile: self.$profileManager.profiles[self.profileManager.profiles.firstIndex(where: { $0.id == profile.id }) ?? 0] )
                    }
                    
                    
                    Button {
                        
                        liveActivityManager.startWorkout(activityProfile: profile)
                        
                        // Set last used date on profile and save to user defaults
                        // Do this after starting workout as may change list binding!!
                        profileManager.update(activityProfile: profile, onlyIfChanged: false)
                        
                        navigateToLiveView = true
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
                    .navigationDestination(isPresented: $navigateToLiveView) {
                        LiveTabView(profileName: profile.name,
                                    liveActivityManager: liveActivityManager,
                                    dataCache: dataCache)
                    }
                }

            }
                
        }
        .onAppear(perform: resetNavigationFlags)
    }

}
    
    
    
     struct ProfileListItemView_Previews: PreviewProvider {
     
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

            ProfileListItemView(profile: .constant(profileManager.profiles[0]),
                                profileManager: profileManager,
                                liveActivityManager: liveActivityManager,
                                dataCache: dataCache)
                 
         }
     }
     
    

