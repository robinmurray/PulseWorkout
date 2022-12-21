//
//  ProfileView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import Foundation
import SwiftUI
import AVFoundation


enum Profile: String, CaseIterable, Identifiable {
    case race, vo2, threshold, aerobic
    var id: Self { self }
}

var profileNames: [String] = ["Race", "VO2 Max", "Threshold", "Aerobic"]


class ProfileData: ObservableObject {
    @Published var hiLimitAlarmActive: Bool
    @Published var hiLimitAlarm: Int
    @Published var loLimitAlarmActive: Bool
    @Published var loLimitAlarm: Int
    @Published var playSound: Bool
    @Published var playHaptic: Bool
    @Published var constantRepeat: Bool
    @Published var lockScreen: Bool
    @Published var profileName: String
    @Published var hrState: HRState = HRState.inactive
    @Published var HRMonitorActive: Bool = false
    @Published var HR: Int = 60
    @Published var appState: AppState = .initial

    
    var playedAlarm: Bool = false
    
    var runCount = 0
    var timer: Timer?
    var HRchange: Int = 10
    var runLimit: Int = 50

    
    init(profileName: String = ""){
    
        // Read profile name from user defaults if nothing passed in
        self.profileName = profileName
        if profileName == "" {
            self.profileName = UserDefaults.standard.string(forKey: "CurrentProfile") ?? "Race"
        }
        
        // Set default values - these will be overwritten by
        // ReadFromUserDefaults
        self.hiLimitAlarmActive = true
        self.hiLimitAlarm = 140
        self.loLimitAlarmActive = false
        self.loLimitAlarm = 100
        self.playSound = false
        self.playHaptic = false
        self.constantRepeat = false
        self.lockScreen = false
        
        ReadFromUserDefaults(profileName: self.profileName)
    }
    
    func ReadFromUserDefaults(profileName: String){
        print("Trying decode")
        
        // Initialise empty dictionary
        // try to read from userDefaults in to this - if fails then use defaults
        var profileDict: [String: Any] = [:]
        
        let profileJSON: Data =  UserDefaults.standard.object(forKey: "Profile_" + profileName) as? Data ?? Data()
        let jsonString = String(data: profileJSON, encoding: .utf8)
        print("Returned profile data : \(String(describing: jsonString))")
        do {
            profileDict = try JSONSerialization.jsonObject(with: profileJSON, options: []) as! [String: Any]
        } catch {
            print("No valid dictionary stored")
        }

        // Read Dictionary or set default values
        self.hiLimitAlarmActive = (profileDict["hiLimitAlarmActive"] ?? true) as! Bool
        self.hiLimitAlarm = (profileDict["hiLimitAlarm"] ?? 140) as! Int
        self.playSound = (profileDict["playSound"] ?? false) as! Bool
        self.playHaptic = (profileDict["playHaptic"] ?? false) as! Bool
        self.constantRepeat = (profileDict["constantRepeat"] ?? false) as! Bool
        self.lockScreen = (profileDict["lockScreen"] ?? false) as! Bool
    }

    func WriteToUserDefaults(profileName: String){

        struct StoredProfile: Codable {
            var hiLimitAlarmActive: Bool
            var hiLimitAlarm: Int
            var playSound: Bool
            var playHaptic: Bool
            var constantRepeat: Bool
            var lockScreen: Bool
        }


        do {
            let storedProfile = StoredProfile(
                hiLimitAlarmActive: hiLimitAlarmActive,
                hiLimitAlarm: hiLimitAlarm,
                playSound: playSound,
                playHaptic: playHaptic,
                constantRepeat: constantRepeat,
                lockScreen: lockScreen)

            
            let data = try JSONEncoder().encode(storedProfile)
            let jsonString = String(data: data, encoding: .utf8)
            print("JSON : \(String(describing: jsonString))")
            UserDefaults.standard.set(data, forKey: "Profile_" + profileName)
        } catch {
            print("Error enconding")
        }
    }
    
    func ChangeProfile(newProfileName: String){

        UserDefaults.standard.set(newProfileName, forKey: "CurrentProfile")
        self.profileName = newProfileName
        ReadFromUserDefaults(profileName: self.profileName)

    }
    
    
    func startStopHRMonitor() {
        
        if !(HRMonitorActive) {
            print("Initialising timer")
            self.runCount = 0
            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
            print("Timer initialised")
            HRMonitorActive = true
            self.hrState = HRState.normal
            
            if lockScreen {
                WKInterfaceDevice.current().enableWaterLock()
            }
            self.appState = .active
        } else {
            self.timer?.invalidate()
            HRMonitorActive = false
            self.hrState = HRState.inactive
            self.appState = .summary
        }
        
    }
    
    @objc func fireTimer() {
        self.runCount += 1
        
        if self.HR > 180 {
            self.HRchange = -10
        }
        if self.HR < 60 {
            self.HRchange = 10
        }
        
        self.HR += self.HRchange
        
        if (self.hiLimitAlarmActive) &&
           (self.HR >= self.hiLimitAlarm) {
            
            self.hrState = HRState.hiAlarm
            
            if (constantRepeat || !playedAlarm) {
                if playSound {
                    WKInterfaceDevice.current().play(.failure)
                }
                if playHaptic {
                    WKInterfaceDevice.current().play(.directionUp)
                }

                playedAlarm = true
            }

            
        } else if (self.loLimitAlarmActive) &&
                    (self.HR <= self.loLimitAlarm) {
            
            self.hrState = HRState.loAlarm
            
            if playSound && (constantRepeat || !playedAlarm) {
                WKInterfaceDevice.current().play(.failure)
                playedAlarm = true
            }
            
        } else {
            self.hrState = HRState.normal
            playedAlarm = false
        }
        
        if self.runCount >= self.runLimit {
            self.startStopHRMonitor()
        }
        
    }

}


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
                    self.profileData.WriteToUserDefaults(profileName: currentProfileName)
                }
                
                Toggle(isOn: $profileData.hiLimitAlarmActive) {
                    Text("High Limit Alarm")
                }
                .onChange(of: profileData.hiLimitAlarmActive) { value in
                    self.profileData.WriteToUserDefaults(profileName: currentProfileName)
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
                    self.profileData.WriteToUserDefaults(profileName: currentProfileName)
                }

                Toggle(isOn: $profileData.loLimitAlarmActive) {
                    Text("Low Limit Alarm")
                }
                .onChange(of: profileData.loLimitAlarmActive) { value in
                    self.profileData.WriteToUserDefaults(profileName: currentProfileName)
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
                .frame(width:160, height: 40, alignment: .topLeading)                .onChange(of: profileData.loLimitAlarm) { value in
                    self.profileData.WriteToUserDefaults(profileName: currentProfileName)
                }

                
                Toggle(isOn: $profileData.playSound) {
                    Text("Play Sound")
                }
                .disabled(!(profileData.hiLimitAlarmActive || profileData.loLimitAlarmActive))
                .onChange(of: profileData.playSound) { value in
                    self.profileData.WriteToUserDefaults(profileName: currentProfileName)
                }

                Toggle(isOn: $profileData.playHaptic) {
                    Text("Play Haptic")
                }
                .disabled(!(profileData.hiLimitAlarmActive || profileData.loLimitAlarmActive))
                .onChange(of: profileData.playHaptic) { value in
                    self.profileData.WriteToUserDefaults(profileName: currentProfileName)
                }

                Toggle(isOn: $profileData.constantRepeat) {
                    Text("Repeat Alarm")
                }
                .disabled(!(profileData.hiLimitAlarmActive || profileData.loLimitAlarmActive))
                .onChange(of: profileData.constantRepeat) { value in
                    self.profileData.WriteToUserDefaults(profileName: currentProfileName)
                }

                
            }
        }
    }
    
    func pickerChanged(newSelectedProfileName: String){
        print("picker changed! to \(currentProfileName)")
        
        self.profileData.ChangeProfile(newProfileName: newSelectedProfileName)

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



