//
//  WorkoutManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 23/12/2022.
//

import Foundation
import HealthKit
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
    @Published var workoutType: HKWorkoutActivityType = HKWorkoutActivityType.cycling
    @Published var workoutLocation: HKWorkoutSessionLocationType = HKWorkoutSessionLocationType.outdoor

    @Published var heartRate: Double = 0
    @Published var distance: Double = 0
    @Published var averageHeartRate: Double = 0
    @Published var heartRateRecovery: Double = 0
    @Published var activeEnergy: Double = 0
    
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
        self.loLimitAlarmActive = (profileDict["loLimitAlarmActive"] ?? false) as! Bool
        self.loLimitAlarm = (profileDict["loLimitAlarm"] ?? 100) as! Int
        self.playSound = (profileDict["playSound"] ?? false) as! Bool
        self.playHaptic = (profileDict["playHaptic"] ?? false) as! Bool
        self.constantRepeat = (profileDict["constantRepeat"] ?? false) as! Bool
        self.lockScreen = (profileDict["lockScreen"] ?? false) as! Bool
    }

    func WriteToUserDefaults(profileName: String){

        struct StoredProfile: Codable {
            var hiLimitAlarmActive: Bool
            var hiLimitAlarm: Int
            var loLimitAlarmActive: Bool
            var loLimitAlarm: Int
            var playSound: Bool
            var playHaptic: Bool
            var constantRepeat: Bool
            var lockScreen: Bool
        }


        do {
            let storedProfile = StoredProfile(
                hiLimitAlarmActive: hiLimitAlarmActive,
                hiLimitAlarm: hiLimitAlarm,
                loLimitAlarmActive: loLimitAlarmActive,
                loLimitAlarm: loLimitAlarm,
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
   
    func PauseHRMonitor() {
        self.appState = .paused
    }
    
    func RestartHRMonitor() {
        self.appState = .live
    }

    func startWorkout() {
        
        // FILL OUT!!
        
    }

    
    func endWorkout() {
        
        // FILL OUT!!
        
    }
    
    func resumeWorkout() {
        
    }
    
    func pauseWorkout() {
        
    }
    
    func requestAuthorization() {
        
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
//                WKInterfaceDevice.current().enableWaterLock()
            }
            self.appState = .live
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
 //                   WKInterfaceDevice.current().play(.failure)
                }
                if playHaptic {
 //                   WKInterfaceDevice.current().play(.directionUp)
                }

                playedAlarm = true
            }

            
        } else if (self.loLimitAlarmActive) &&
                    (self.HR <= self.loLimitAlarm) {
            
            self.hrState = HRState.loAlarm
            
            if playSound && (constantRepeat || !playedAlarm) {
 //               WKInterfaceDevice.current().play(.failure)
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


class WorkoutManager: NSObject, ObservableObject {
    
    var selectedWorkout: HKWorkoutActivityType?
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    
    func startWorkout(workoutType: HKWorkoutActivityType) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession( healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            print("Failed to start Workout Session")
            return
        }
        
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
     
        // Start the session and collect data
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            // workout started
        }
        
    }
    
    func requestAuthorization() {
        // the quantity type to write to healthStore
        let typesToShare: Set = [HKWorkoutType.workoutType()]
        
        // the quantity types to read from healthStore
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]

        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)  { (success, error) in
            if !success {
                // Handle the error here.
                print("Authorisation Failed")
            }
        }
    }
}
