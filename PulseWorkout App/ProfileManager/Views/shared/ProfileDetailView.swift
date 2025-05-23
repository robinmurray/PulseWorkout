//
//  ProfileDetailView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 14/04/2023.
//

import SwiftUI
import HealthKit


struct ProfileDetailForm: View {
  
    @Binding var profile: ActivityProfile
   
    var workoutTypes: [HKWorkoutActivityType] = [.crossTraining, .cycling, .flexibility, .functionalStrengthTraining, .mixedCardio, .paddleSports, .rowing, .running, .walking]
    var workoutLocations: [HKWorkoutSessionLocationType] = [.indoor, .outdoor]

    
    var body: some View {
 

        Section(header: Text("Profile Name")) {
            TextField(
                "Profile",
                text: $profile.name
            )
            .font(.system(size: 15))
            .fontWeight(.bold)
            .foregroundStyle(.orange)
                
        }
            
        Section(header: Text("Workout type")) {
            
            Picker("Workout Type", selection: $profile.workoutTypeId) {
                ForEach(workoutTypes) { workoutType in
                    Label(workoutType.name, systemImage: workoutType.iconImage).tag(workoutType.self)
                }
            }
            .font(.headline)
            .foregroundColor(Color.blue)
            .fontWeight(.bold)
            #if os(watchOS)
            .listStyle(.carousel)
            #endif
            .onChange(of: profile.workoutTypeId) {
                
            }
                
                
            Picker("Workout Location", selection: $profile.workoutLocationId) {
                ForEach(workoutLocations) { workoutLocation in
                    Text(workoutLocation.name).tag(workoutLocation.self)
                }
            }
            .font(.headline)
            .foregroundColor(Color.blue)
            .fontWeight(.bold)
            #if os(watchOS)
            .listStyle(.carousel)
            #endif
                
        }

        Section(header: Text("Actions")) {

            Toggle(isOn: $profile.autoPause) {
                Text("Auto-Pause")
            }
              
            Toggle(isOn: $profile.lockScreen) {
                Text("Lock Screen")
            }
        }
        
        Section(header: Text("Heart Rate Profile")) {
                
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
        
        Section(header: Text("Strava Integration")) {
            VStack {
                
                HStack {
                    Text("To enable this section, in Settings: Strava Integration must be enabled, Enable save to Strava must be on, and Set save options by activity profile must be on.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }
                
                Toggle(isOn: $profile.stravaSaveAll) {
                    Text("Auto-save all activities to Strava")
                }
                HStack {
                    Text("If enabled, then all new activities of this type will be automatically saved to Strava. If not enabled, then a button is provided on each activity detail screen to optionally save to Strava")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }
                
            }

            
        }.disabled(!SettingsManager.shared.offerSaveByProfile() )

    }

}

struct ProfileDetailView: View {

    @ObservedObject var profileManager: ProfileManager

    @Binding var profile: ActivityProfile
    @State var deleteProfile = false
    @Environment(\.dismiss) private var dismiss
    
    var workoutTypes: [HKWorkoutActivityType] = [.crossTraining, .cycling, .mixedCardio, .paddleSports, .rowing, .running, .walking]
    var workoutLocations: [HKWorkoutSessionLocationType] = [.indoor, .outdoor]


    func delete() {
        deleteProfile = true
        dismiss()
    }
    
    var body: some View {
        
        VStack{
            Form {
                ProfileDetailForm(profile: $profile)

                Section() {
                    Button(action: delete) {
                        Text("Delete")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.red)
                    .buttonStyle(PlainButtonStyle())

                }
            }
            #if os(watchOS)
            .navigationTitle {
                Label("Edit Profile", systemImage: "figure.run")
                    .foregroundColor(.orange)
            }
            #endif
            .onDisappear {
                if deleteProfile {
                    profileManager.remove(activityProfile: profile)
                } else {
                    profileManager.update(activityProfile: profile, onlyIfChanged: true)
                }

            }
        }

    }
}





struct ProfileDetailView_Previews: PreviewProvider {
    static var profileManager = ProfileManager()
    
    static var previews: some View {
        ProfileDetailView(profileManager: profileManager,
                          profile: .constant(profileManager.profiles[0]) )
    }
}

