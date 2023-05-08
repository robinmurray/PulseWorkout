//
//  ProfileListItemView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 13/04/2023.
//

import SwiftUI



struct ProfileListItemView: View {
    
    @Binding var profile: ActivityProfile
    @ObservedObject var profileManager: ActivityProfiles
    @ObservedObject var workoutManager: WorkoutManager

    @State private var navigateToDetailView : Bool = false
    @State private var navigateToLiveView : Bool = false
    
    // set navigation flags to false when view appears.
    // this allows view to reappear and navigation to work successfully!
    func resetNavigationFlags() {
        navigateToDetailView = false
        navigateToLiveView = false
    }
    
    let hiAlarmDisplay: [Bool: AlarmStyling] =
    [false: AlarmStyling(alarmLevelText: "___", colour: Color.gray),
     true: AlarmStyling(colour: Color.red)]
    
    let loAlarmDisplay: [Bool: AlarmStyling] =
    [false: AlarmStyling(alarmLevelText: "___", colour: Color.gray),
     true: AlarmStyling(colour: Color.orange)]
    
    func startWorkout() {
        workoutManager.startWorkout(activityProfile: profile)
    }
    
    var body: some View {
        VStack {
            Text(profile.name)
                .font(.system(size: 15))
                .fontWeight(.bold)
                .foregroundStyle(.yellow)

  
            HStack {
                
                NavigationStack {
                    VStack {
                        Button {
                            navigateToDetailView = true
                        } label: {
                            VStack{
                                Image(systemName: "pencil.circle")
                                    .foregroundColor(Color.green)
                                    .font(.title)
                                    .frame(width: 40, height: 40)
                                    .background(Color.clear)
                                    .clipShape(Circle())
                                    .buttonStyle(PlainButtonStyle())
                                
                                Text("Edit")
                                    .foregroundColor(Color.green)
                            }
                            
                        }
                        .tint(Color.green)
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .navigationDestination(isPresented: $navigateToDetailView) {
                        ProfileDetailView(profile: $profile, profileManager: profileManager)
                    }
                }

                
                 
                Spacer().frame(maxWidth: .infinity)


                NavigationStack {
                    VStack {
                        Button {
                            workoutManager.startWorkout(activityProfile: profile)
                            print("navigateToLiveView \(navigateToLiveView)")
                            navigateToLiveView = true
                            print("navigateToLiveView \(navigateToLiveView)")
                        } label: {
                            VStack{
                                Image(systemName: "play.circle")
                                    .foregroundColor(Color.green)
                                    .font(.title)
                                    .frame(width: 40, height: 40)
                                    .background(Color.clear)
                                    .clipShape(Circle())
                                    .buttonStyle(PlainButtonStyle())
                                
                                Text("Start")
                                    .foregroundColor(Color.green)
                            }
                            
                        }
                        .tint(Color.green)
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .navigationDestination(isPresented: $navigateToLiveView) {
                        LiveTabView(profile: $profile, workoutManager: workoutManager)
                    }
                }
            }
        

                HStack {
                    Image(systemName:"heart.fill")
                        .foregroundColor(Color.red)
                    
                    Image(systemName: "arrow.down.to.line.circle.fill")
                        .foregroundColor(loAlarmDisplay[profile.loLimitAlarmActive]?.colour)
                        .frame(height: 20)
                    
                    Text(loAlarmDisplay[profile.loLimitAlarmActive]?.alarmLevelText ?? String(profile.loLimitAlarm))
                        .foregroundColor(loAlarmDisplay[profile.loLimitAlarmActive]?.colour)
                        .font(.system(size: 15))
                    
                    Image(systemName: "arrow.up.to.line.circle.fill")
                        .foregroundColor(hiAlarmDisplay[profile.hiLimitAlarmActive]?.colour)
                        .frame(height: 20)
                    
                    Text(hiAlarmDisplay[profile.hiLimitAlarmActive]?.alarmLevelText ?? String(profile.hiLimitAlarm))
                        .foregroundColor(hiAlarmDisplay[profile.hiLimitAlarmActive]?.colour)
                        .font(.system(size: 15))
                }
            }
        .onAppear(perform: resetNavigationFlags)
        }

    }
    
    
    /*
     struct ProfileListItemView_Previews: PreviewProvider {
     
     static var profiles: ActivityProfiles = ActivityProfiles()
     static var workoutManager = WorkoutManager()
     @Binding var profile: ActivityProfile = projectedValue<[ActivityProfile]>[0]
     
     static var previews: some View {
     
     let profile = profiles.profiles[0]
     ProfileListItemView(profile: profile, workoutManager: workoutManager)
     }
     }
     */
    

