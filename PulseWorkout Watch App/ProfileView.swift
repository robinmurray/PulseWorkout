//
//  ProfileView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//
import Foundation
import SwiftUI



struct ProfileView: View {
    
    @State private var currentProfileName: String
    @State private var profileNames: [String] = ["Race", "VO2 Max", "Threshold", "Aerobic"]

    @ObservedObject var workoutManager: WorkoutManager
        

    init(workoutManager: WorkoutManager) {

        currentProfileName = workoutManager.profileName
        
        self.workoutManager = workoutManager

    }
    
    var body: some View {
        VStack{
            Form {
                Picker("Profile", selection: $currentProfileName) {
                    ForEach(self.profileNames, id: \.self) { status in
                        Text(status)
                    }
                }
                .onChange(of: currentProfileName) { _ in
                    pickerChanged(newSelectedProfileName: currentProfileName )
                        }
                .font(.headline)
                .foregroundColor(Color.blue)
                .fontWeight(.bold)

                Toggle(isOn: $workoutManager.lockScreen) {
                    Text("Lock Screen")
                }
                .onChange(of: workoutManager.lockScreen) { value in
                    self.workoutManager.writeProfileToUserDefaults(profileName: currentProfileName)
                }
                
                Toggle(isOn: $workoutManager.hiLimitAlarmActive) {
                    Text("High Limit Alarm")
                }
                .onChange(of: workoutManager.hiLimitAlarmActive) { value in
                    self.workoutManager.writeProfileToUserDefaults(profileName: currentProfileName)
                }
                
                
                Stepper(value: $workoutManager.hiLimitAlarm,
                        in: 1...220,
                        step: 1) {
                    Text("\(workoutManager.hiLimitAlarm)")
                }
                .disabled(!workoutManager.hiLimitAlarmActive)
                .font(.headline)
                .fontWeight(.light)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.20)
                .frame(width:160, height: 40, alignment: .topLeading)
                .onChange(of: workoutManager.hiLimitAlarm) { value in
                    self.workoutManager.writeProfileToUserDefaults(profileName: currentProfileName)
                }

                Toggle(isOn: $workoutManager.loLimitAlarmActive) {
                    Text("Low Limit Alarm")
                }
                .onChange(of: workoutManager.loLimitAlarmActive) { value in
                    self.workoutManager.writeProfileToUserDefaults(profileName: currentProfileName)
                }
                
                
                Stepper(value: $workoutManager.loLimitAlarm,
                        in: 1...220,
                        step: 1) {
                    Text("\(workoutManager.loLimitAlarm)")
                }
                .disabled(!workoutManager.loLimitAlarmActive)
                .font(.headline)
                .fontWeight(.light)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.20)
                .frame(width:160, height: 40, alignment: .topLeading)
                .onChange(of: workoutManager.loLimitAlarm) { value in
                    self.workoutManager.writeProfileToUserDefaults(profileName: currentProfileName)
                }

                
                Toggle(isOn: $workoutManager.playSound) {
                    Text("Play Sound")
                }
                .disabled(!(workoutManager.hiLimitAlarmActive || workoutManager.loLimitAlarmActive))
                .onChange(of: workoutManager.playSound) { value in
                    self.workoutManager.writeProfileToUserDefaults(profileName: currentProfileName)
                }

                Toggle(isOn: $workoutManager.playHaptic) {
                    Text("Play Haptic")
                }
                .disabled(!(workoutManager.hiLimitAlarmActive || workoutManager.loLimitAlarmActive))
                .onChange(of: workoutManager.playHaptic) { value in
                    self.workoutManager.writeProfileToUserDefaults(profileName: currentProfileName)
                }

                Toggle(isOn: $workoutManager.constantRepeat) {
                    Text("Repeat Alarm")
                }
                .disabled(!(workoutManager.hiLimitAlarmActive || workoutManager.loLimitAlarmActive))
                .onChange(of: workoutManager.constantRepeat) { value in
                    self.workoutManager.writeProfileToUserDefaults(profileName: currentProfileName)
                }


            }
            .navigationTitle("Alarm Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func pickerChanged(newSelectedProfileName: String){
        print("picker changed! to \(currentProfileName)")
        
        self.workoutManager.changeProfile(newProfileName: newSelectedProfileName)

        self.currentProfileName = newSelectedProfileName

    }
    
    func activateProfile(){
        print("Activate Profile")
    }
}


struct ProfileView_Previews: PreviewProvider {
    
    static var workoutManager = WorkoutManager(profileName: "Race")
    
    static var previews: some View {
        ProfileView(workoutManager: workoutManager)
    }
}



