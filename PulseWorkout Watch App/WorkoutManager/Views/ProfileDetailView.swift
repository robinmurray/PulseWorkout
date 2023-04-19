//
//  ProfileDetailView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 14/04/2023.
//

import SwiftUI
import HealthKit


struct ProfileDetailView: View {

    @Binding var profile: ActivityProfile
    @ObservedObject var profileManager: ActivityProfiles


    @Environment(\.dismiss) private var dismiss
    
    var workoutTypes: [HKWorkoutActivityType] = [.crossTraining, .cycling, .mixedCardio, .paddleSports, .rowing, .running, .walking]
    var workoutLocations: [HKWorkoutSessionLocationType] = [.indoor, .outdoor, .unknown]

    func delete() {
        profileManager.remove(activityProfile: profile)
        dismiss()
    }
    
    var body: some View {
        
        VStack{
            Form {
                Section(header: Text("Profile Name")) {
                    TextField(
                        "Profile",
                        text: $profile.name
                    )
                    .font(.system(size: 15))
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow)

                }

                Section(header: Text("Workout type")) {

                    Picker("Workout Type", selection: $profile.workoutTypeId) {
                        ForEach(workoutTypes) { workoutType in
                            Text(workoutType.name).tag(workoutType.self)
                        }
                    }
                    .font(.headline)
                    .foregroundColor(Color.blue)
                    .fontWeight(.bold)
                    .listStyle(.carousel)

                    
                    Picker("Workout Location", selection: $profile.workoutLocationId) {
                        ForEach(workoutLocations) { workoutLocation in
                            Text(workoutLocation.name).tag(workoutLocation.self)
                        }
                    }
                    .font(.headline)
                    .foregroundColor(Color.blue)
                    .fontWeight(.bold)
                    .listStyle(.carousel)

                }

                Section(header: Text("Heart Rate Profile")) {
                    
                    Toggle(isOn: $profile.lockScreen) {
                        Text("Lock Screen")
                    }

                    Toggle(isOn: $profile.hiLimitAlarmActive) {
                        Text("High Limit Alarm")
                    }
                    
                    Stepper(value: $profile.hiLimitAlarm,
                            in: 1...220,
                            step: 1) { Text("\(profile.hiLimitAlarm)")
                    }
                    .disabled(!profile.hiLimitAlarmActive)
                    .font(.headline)
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.20)
                    .frame(width:160, height: 40, alignment: .topLeading)
                    
                    
                    Toggle(isOn: $profile.loLimitAlarmActive) {
                        Text("Low Limit Alarm")
                    }
                    
                    Stepper(value: $profile.loLimitAlarm,
                            in: 1...220,
                            step: 1) {
                        Text("\(profile.loLimitAlarm)")
                    }
                    .disabled(!profile.loLimitAlarmActive)
                    .font(.headline)
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.20)
                    .frame(width:160, height: 40, alignment: .topLeading)
                    
                    Toggle(isOn: $profile.playSound) {
                        Text("Play Sound")
                    }
                    .disabled(!(profile.hiLimitAlarmActive || profile.loLimitAlarmActive))
                    
                    Toggle(isOn: $profile.playHaptic) {
                        Text("Play Haptic")
                    }
                    .disabled(!(profile.hiLimitAlarmActive || profile.loLimitAlarmActive))
                    
                    Toggle(isOn: $profile.constantRepeat) {
                        Text("Repeat Alarm")
                    }
                    .disabled(!(profile.hiLimitAlarmActive || profile.loLimitAlarmActive))
                     
                }
 
                Section() {
                    Button(action: delete) {
                        Text("Delete")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.red)
                    .buttonStyle(PlainButtonStyle())

                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                profileManager.write()
            }

        }

    }
}

/*
struct ProfileDetailView_Previews: PreviewProvider {
    static var profileManager = ActivityProfiles()
    
    static var previews: some View {
        ProfileDetailView(profile: .constant(profileManager.profiles[0]),
                          profileManager: profileManager, new: false)
    }
}
*/
