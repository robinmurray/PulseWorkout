//
//  ProfileDetailView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 14/04/2023.
//

import SwiftUI
import HealthKit


struct ProfileDetailView: View {

    @ObservedObject var profileManager: ActivityProfiles
    var profileIndex: Int

    @Environment(\.dismiss) private var dismiss
    
    var workoutTypes: [HKWorkoutActivityType] = [.crossTraining, .cycling, .mixedCardio, .paddleSports, .rowing, .running, .walking]
    var workoutLocations: [HKWorkoutSessionLocationType] = [.indoor, .outdoor, .unknown]


    func delete() {
        profileManager.remove(activityProfile: profileManager.profiles[profileIndex])
        dismiss()
    }
    
    var body: some View {
        
        VStack{
            Form {
                Section(header: Text("Profile Name")) {
                    TextField(
                        "Profile",
                        text: $profileManager.profiles[profileIndex].name
                    )
                    .font(.system(size: 15))
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow)

                }

                Section(header: Text("Workout type")) {

                    Picker("Workout Type", selection: $profileManager.profiles[profileIndex].workoutTypeId) {
                        ForEach(workoutTypes) { workoutType in
                            Text(workoutType.name).tag(workoutType.self)
                        }
                    }
                    .font(.headline)
                    .foregroundColor(Color.blue)
                    .fontWeight(.bold)
                    .listStyle(.carousel)

                    
                    Picker("Workout Location", selection: $profileManager.profiles[profileIndex].workoutLocationId) {
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
                    
                    Toggle(isOn: $profileManager.profiles[profileIndex].lockScreen) {
                        Text("Lock Screen")
                    }

                    Toggle(isOn: $profileManager.profiles[profileIndex].hiLimitAlarmActive) {
                        Text("High Limit Alarm")
                    }
                    
                    Stepper(value: $profileManager.profiles[profileIndex].hiLimitAlarm,
                            in: 1...220,
                            step: 1) { Text("\(profileManager.profiles[profileIndex].hiLimitAlarm)")
                    }
                    .disabled(!profileManager.profiles[profileIndex].hiLimitAlarmActive)
                    .font(.headline)
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.20)
                    .frame(width:160, height: 40, alignment: .topLeading)
                    
                    
                    Toggle(isOn: $profileManager.profiles[profileIndex].loLimitAlarmActive) {
                        Text("Low Limit Alarm")
                    }
                    
                    Stepper(value: $profileManager.profiles[profileIndex].loLimitAlarm,
                            in: 1...220,
                            step: 1) {
                        Text("\(profileManager.profiles[profileIndex].loLimitAlarm)")
                    }
                    .disabled(!profileManager.profiles[profileIndex].loLimitAlarmActive)
                    .font(.headline)
                    .fontWeight(.light)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.20)
                    .frame(width:160, height: 40, alignment: .topLeading)
                    
                    Toggle(isOn: $profileManager.profiles[profileIndex].playSound) {
                        Text("Play Sound")
                    }
                    .disabled(!(profileManager.profiles[profileIndex].hiLimitAlarmActive || profileManager.profiles[profileIndex].loLimitAlarmActive))
                    
                    Toggle(isOn: $profileManager.profiles[profileIndex].playHaptic) {
                        Text("Play Haptic")
                    }
                    .disabled(!(profileManager.profiles[profileIndex].hiLimitAlarmActive || profileManager.profiles[profileIndex].loLimitAlarmActive))
                    
                    Toggle(isOn: $profileManager.profiles[profileIndex].constantRepeat) {
                        Text("Repeat Alarm")
                    }
                    .disabled(!(profileManager.profiles[profileIndex].hiLimitAlarmActive || profileManager.profiles[profileIndex].loLimitAlarmActive))
                     
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
                profileManager.update(activityProfile: profileManager.profiles[profileIndex], onlyIfChanged: true)

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
