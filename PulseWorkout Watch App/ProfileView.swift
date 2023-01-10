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

    @ObservedObject var profileData: ProfileData
        

    init(profileData: ProfileData) {

        currentProfileName = profileData.profileName
        
        self.profileData = profileData

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

                Toggle(isOn: $profileData.lockScreen) {
                    Text("Lock Screen")
                }
                .onChange(of: profileData.lockScreen) { value in
                    self.profileData.writeProfileToUserDefaults(profileName: currentProfileName)
                }
                
                Toggle(isOn: $profileData.hiLimitAlarmActive) {
                    Text("High Limit Alarm")
                }
                .onChange(of: profileData.hiLimitAlarmActive) { value in
                    self.profileData.writeProfileToUserDefaults(profileName: currentProfileName)
                }
                
                
                Stepper(value: $profileData.hiLimitAlarm,
                        in: 1...220,
                        step: 1) {
                    Text("\(profileData.hiLimitAlarm)")
                }
                .disabled(!profileData.hiLimitAlarmActive)
                .font(.headline)
                .fontWeight(.light)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.20)
                .frame(width:160, height: 40, alignment: .topLeading)
                .onChange(of: profileData.hiLimitAlarm) { value in
                    self.profileData.writeProfileToUserDefaults(profileName: currentProfileName)
                }

                Toggle(isOn: $profileData.loLimitAlarmActive) {
                    Text("Low Limit Alarm")
                }
                .onChange(of: profileData.loLimitAlarmActive) { value in
                    self.profileData.writeProfileToUserDefaults(profileName: currentProfileName)
                }
                
                
                Stepper(value: $profileData.loLimitAlarm,
                        in: 1...220,
                        step: 1) {
                    Text("\(profileData.loLimitAlarm)")
                }
                .disabled(!profileData.loLimitAlarmActive)
                .font(.headline)
                .fontWeight(.light)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.20)
                .frame(width:160, height: 40, alignment: .topLeading)
                .onChange(of: profileData.loLimitAlarm) { value in
                    self.profileData.writeProfileToUserDefaults(profileName: currentProfileName)
                }

                
                Toggle(isOn: $profileData.playSound) {
                    Text("Play Sound")
                }
                .disabled(!(profileData.hiLimitAlarmActive || profileData.loLimitAlarmActive))
                .onChange(of: profileData.playSound) { value in
                    self.profileData.writeProfileToUserDefaults(profileName: currentProfileName)
                }

                Toggle(isOn: $profileData.playHaptic) {
                    Text("Play Haptic")
                }
                .disabled(!(profileData.hiLimitAlarmActive || profileData.loLimitAlarmActive))
                .onChange(of: profileData.playHaptic) { value in
                    self.profileData.writeProfileToUserDefaults(profileName: currentProfileName)
                }

                Toggle(isOn: $profileData.constantRepeat) {
                    Text("Repeat Alarm")
                }
                .disabled(!(profileData.hiLimitAlarmActive || profileData.loLimitAlarmActive))
                .onChange(of: profileData.constantRepeat) { value in
                    self.profileData.writeProfileToUserDefaults(profileName: currentProfileName)
                }


            }
        }
    }
    
    func pickerChanged(newSelectedProfileName: String){
        print("picker changed! to \(currentProfileName)")
        
        self.profileData.changeProfile(newProfileName: newSelectedProfileName)

        self.currentProfileName = newSelectedProfileName

    }
    
    func activateProfile(){
        print("Activate Profile")
    }
}


struct ProfileView_Previews: PreviewProvider {
    
    static var profileData = ProfileData(profileName: "Race")
    
    static var previews: some View {
        ProfileView(profileData: profileData)
    }
}



