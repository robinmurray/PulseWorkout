//
//  ProfileListItemView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 18/11/2024.
//

import SwiftUI
import HealthKit

struct AlarmStyling {
    var alarmLevelText: String?
    var colour: Color
}

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
        NavigationStack {
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
                
                Button {
                    
                    liveActivityManager.startWorkout(activityProfile: profile)
                    
                    // Set last used date on profile and save to user defaults
                    // Do this after starting workout as may change list binding!!
                    profileManager.update(activityProfile: profile, onlyIfChanged: false)
                    
                    navigateToLiveView = true
                } label: {
                    HStack{
                        Text("Start").font(.title)
                        Image(systemName: "play.circle").font(.title)

                    }
                    
                }
                .tint(Color.green)
                .buttonStyle(.bordered)
//                 .buttonStyle(BorderlessButtonStyle())
/* FIX                    .navigationDestination(isPresented: $navigateToLiveView) {
                    LiveTabView(profileName: profile.name,
                                liveActivityManager: liveActivityManager,
                                dataCache: dataCache)
                }
--FIX */
                .navigationDestination(isPresented: $navigateToLiveView) {
                    ActivityHistoryHeaderView()
              }

                  
            }
            .swipeActions {
                Button(role:.destructive) {
                    profileManager.remove(activityProfile: profile)
                } label: {
                    Label("Delete", systemImage: "xmark.bin")
                }
            }
            
            HStack {
                Button {
                    navigateToDetailView = true
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
                .navigationDestination(isPresented: $navigateToDetailView) {
                    ProfileDetailView(profileManager: profileManager,
                                      profile: self.$profileManager.profiles[self.profileManager.profiles.firstIndex(where: { $0.id == profile.id }) ?? 0] )
                }
                Spacer()
            }
            
        }
        .onAppear(perform: resetNavigationFlags)
    }

}
    

#Preview {
    let settingsManager = SettingsManager()
    let dataCache = DataCache(settingsManager: settingsManager)
    let locationManager = LocationManager(settingsManager: settingsManager)
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         settingsManager: settingsManager,
                                                         dataCache: dataCache)
    let profileManager = ProfileManager()
    
    ProfileListItemView(profile: .constant(profileManager.profiles[0]),
                        profileManager: profileManager,
                        liveActivityManager: liveActivityManager,
                        dataCache: dataCache)
}
