//
//  ProfileView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//
import Foundation
import SwiftUI
import HealthKit


struct ProfileView: View {
    
    @ObservedObject var workoutManager: WorkoutManager

    var workoutTypes: [HKWorkoutActivityType] = [.crossTraining, .cycling, .mixedCardio, .paddleSports, .rowing, .running, .walking]
    
    var workoutLocations: [HKWorkoutSessionLocationType] = [.indoor, .outdoor, .unknown]



    init(workoutManager: WorkoutManager) {

        self.workoutManager = workoutManager

    }
    
    func done() {
        workoutManager.writeLiveActivityProfile()

        workoutManager.appState = .initial
    }
    
    func dismiss() {
        workoutManager.appState = .initial
    }
    
    func delete() {
        workoutManager.deleteLiveActivityProfile()

        workoutManager.appState = .initial
    }
    
    var body: some View {
        VStack{

            Form {
                
                Section(header: Text("Profile Name")) {
                    TextField(
                        "Profile",
                        text: $workoutManager.liveActivityProfile.name
                    )
                    .font(.system(size: 15))
                    .fontWeight(.bold)
                    .foregroundStyle(.yellow)


                }
                Section(header: Text("Workout type")) {
                    Picker("Workout Type", selection: $workoutManager.workoutType) {
                        ForEach(workoutTypes) { workoutType in
                            Text(workoutType.name).tag(workoutType.self)
                        }
                    }
                    .font(.headline)
                    .foregroundColor(Color.blue)
                    .fontWeight(.bold)
                    .listStyle(.carousel)

                    
                    Picker("Workout Location", selection: $workoutManager.workoutLocation) {
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
                    
                    Toggle(isOn: $workoutManager.liveActivityProfile.lockScreen) {
                        Text("Lock Screen")
                    }
                    
                    Toggle(isOn: $workoutManager.liveActivityProfile.hiLimitAlarmActive) {
                        Text("High Limit Alarm")
                    }
                    
                    Stepper(value: $workoutManager.liveActivityProfile.hiLimitAlarm,
                            in: 1...220,
                            step: 1) { Text("\(workoutManager.liveActivityProfile.hiLimitAlarm)")
                    }
                            .disabled(!workoutManager.liveActivityProfile.hiLimitAlarmActive)
                            .font(.headline)
                            .fontWeight(.light)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.20)
                            .frame(width:160, height: 40, alignment: .topLeading)
                    
                    
                    Toggle(isOn: $workoutManager.liveActivityProfile.loLimitAlarmActive) {
                        Text("Low Limit Alarm")
                    }
                    
                    Stepper(value: $workoutManager.liveActivityProfile.loLimitAlarm,
                            in: 1...220,
                            step: 1) {
                        Text("\(workoutManager.liveActivityProfile.loLimitAlarm)")
                    }
                            .disabled(!workoutManager.liveActivityProfile.loLimitAlarmActive)
                            .font(.headline)
                            .fontWeight(.light)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.20)
                            .frame(width:160, height: 40, alignment: .topLeading)
                    
                    
                    
                    Toggle(isOn: $workoutManager.liveActivityProfile.playSound) {
                        Text("Play Sound")
                    }
                    .disabled(!(workoutManager.liveActivityProfile.hiLimitAlarmActive || workoutManager.liveActivityProfile.loLimitAlarmActive))
                    
                    Toggle(isOn: $workoutManager.liveActivityProfile.playHaptic) {
                        Text("Play Haptic")
                    }
                    .disabled(!(workoutManager.liveActivityProfile.hiLimitAlarmActive || workoutManager.liveActivityProfile.loLimitAlarmActive))
                    
                    Toggle(isOn: $workoutManager.liveActivityProfile.constantRepeat) {
                        Text("Repeat Alarm")
                    }
                    .disabled(!(workoutManager.liveActivityProfile.hiLimitAlarmActive || workoutManager.liveActivityProfile.loLimitAlarmActive))
                }
                Section() {
                    Button("Done", action: { done() } )
                        .buttonStyle(.borderedProminent)
                        .tint(Color.blue)

                    Button("Dismiss", action: { dismiss() })
                        .buttonStyle(.borderedProminent)
                        .tint(Color.gray)


                    Button(action: delete) {
                        Text("Delete")
//                        Image(systemName: "xmark.bin.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.red)
                    .buttonStyle(PlainButtonStyle())

                }
            }
//            .padding()
            .navigationTitle("Alarm Profile")
            .navigationBarTitleDisplayMode(.inline)
            

        }
    }
    
}


struct ProfileView_Previews: PreviewProvider {
    
    static var workoutManager = WorkoutManager(profileName: "Race")
    
    static var previews: some View {
        ProfileView(workoutManager: workoutManager)
    }
}



