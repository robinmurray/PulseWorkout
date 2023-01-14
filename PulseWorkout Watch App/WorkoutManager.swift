//
//  WorkoutManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 23/12/2022.
//

import Foundation
import HealthKit
import AVFoundation
import WatchKit


struct SummaryMetrics: Codable {
    var duration: Double
    var averageHeartRate: Double
    var heartRateRecovery: Double
    var activeEnergy: Double
    var distance: Double
}


enum Profile: String, CaseIterable, Identifiable {
    case race, vo2, threshold, aerobic
    var id: Self { self }
}

var profileNames: [String] = ["Race", "VO2 Max", "Threshold", "Aerobic"]


class ProfileData: NSObject, ObservableObject {
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
    @Published var appState: AppState = .initial
    @Published var workoutType: HKWorkoutActivityType = HKWorkoutActivityType.cycling
    @Published var workoutLocation: HKWorkoutSessionLocationType = HKWorkoutSessionLocationType.outdoor

    @Published var heartRate: Double = 0
    @Published var distance: Double = 0
   
    @Published var workout: HKWorkout?
    @Published var running = false
    
    var playedAlarm: Bool = false
    
    var runCount = 0
    var timer: Timer?
    var HRchange: Int = 10
    var runLimit: Int = 50

    var selectedWorkout: HKWorkoutActivityType?
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?

    @Published var summaryMetrics = SummaryMetrics(
        duration: 0,
        averageHeartRate: 0,
        heartRateRecovery: 0,
        activeEnergy: 0,
        distance: 0
        )
    
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
        
        super.init()
        
        readProfileFromUserDefaults(profileName: self.profileName)
        readWorkoutConfFromUserDefaults()
    }
    
    func readProfileFromUserDefaults(profileName: String){
        print("Trying decode profile")
        
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

    func writeProfileToUserDefaults(profileName: String){

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
    
    func changeProfile(newProfileName: String){

        UserDefaults.standard.set(newProfileName, forKey: "CurrentProfile")
        self.profileName = newProfileName
        readProfileFromUserDefaults(profileName: self.profileName)

    }

    
    func writeWorkoutConfToUserDefaults(){

        struct StoredWorkoutConf: Codable {
            var workoutType: UInt
            var workoutLocation: Int
        }


        do {
            let storedWorkoutConf = StoredWorkoutConf(
                workoutType: workoutType.rawValue,
                workoutLocation: workoutLocation.rawValue)

            
            let data = try JSONEncoder().encode(storedWorkoutConf)
            let jsonString = String(data: data, encoding: .utf8)
            print("JSON : \(String(describing: jsonString))")
            UserDefaults.standard.set(data, forKey: "WorkoutConf")
        } catch {
            print("Error enconding Workout Configuration")
        }
    }

    func readWorkoutConfFromUserDefaults(){
        print("Trying decode Workout Configuration")
        
        // Initialise empty dictionary
        // try to read from userDefaults in to this - if fails then use defaults
        var workoutConfDict: [String: Any] = [:]
        
        let workoutConfJSON: Data =  UserDefaults.standard.object(forKey: "WorkoutConf") as? Data ?? Data()
        let jsonString = String(data: workoutConfJSON, encoding: .utf8)
        print("Returned Workout Configuration data : \(String(describing: jsonString))")
        do {
            workoutConfDict = try JSONSerialization.jsonObject(with: workoutConfJSON, options: []) as! [String: Any]
        } catch {
            print("No valid dictionary stored")
        }

        // Read Dictionary or set default values
        self.workoutLocation = HKWorkoutSessionLocationType(rawValue: (workoutConfDict["workoutLocation"] ?? HKWorkoutSessionLocationType.outdoor.rawValue) as! Int)!
        self.workoutType = HKWorkoutActivityType(rawValue: (workoutConfDict["workoutType"] ?? HKWorkoutActivityType.cycling.rawValue) as! UInt)!
    }

    func PauseHRMonitor() {
        self.appState = .paused
    }
    
    func RestartHRMonitor() {
        self.appState = .live
    }

    func startWorkout() {
        startStopHRMonitor()
        // FILL OUT!!
     
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = workoutLocation
        
        do {
            session = try HKWorkoutSession( healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            print("Failed to start Workout Session")
            return
        }
        
        // Setup session and builder.
        session?.delegate = self
        builder?.delegate = self

        // Set the workout builder's data source.
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: configuration)

        // Start the workout session and begin data collection.
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            // The workout has started.
            if !success {
                            // Handle the error here.
                print("Workout start Failed with error: \(String(describing: error))")
            } else {
                print("Workout Started")
            }
        }
        
        if self.lockScreen && !WKInterfaceDevice.current().isWaterLockEnabled {
            Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(delayedEnableWaterLock), userInfo: nil, repeats: false)
        }

    }

    func endWorkout() {
        session?.end()
        startStopHRMonitor()
        
    }
    
    func resumeWorkout() {
        session?.resume()
        appState = .live
    }
    
    func pauseWorkout() {
        session?.pause()
        appState = .paused
    }
    
    
    func startStopHRMonitor() {
        
        if !(HRMonitorActive) {
            print("Initialising timer")
            self.runCount = 0
            self.timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
            print("Timer initialised")
            HRMonitorActive = true
            self.hrState = HRState.normal
            
            self.appState = .live
        } else {
            self.timer?.invalidate()
            HRMonitorActive = false
            self.hrState = HRState.inactive
            self.appState = .summary
        }
        
    }
    
    @objc func delayedEnableWaterLock() {
        
        WKInterfaceDevice.current().enableWaterLock()
        
    }
    
    
    @objc func fireTimer() {
        self.runCount += 1

        if (self.hiLimitAlarmActive) &&
           (Int(self.heartRate) >= self.hiLimitAlarm) {
            
            self.hrState = HRState.hiAlarm
            
            if (constantRepeat || !playedAlarm) {
                if playSound {
                    WKInterfaceDevice.current().play(.failure)
                    print("playing sound 1")
                }
                if playHaptic {
                    WKInterfaceDevice.current().play(.directionUp)
                    print("playing sound 2")                }

                playedAlarm = true
            }

            
        } else if (self.loLimitAlarmActive) &&
                    (Int(self.heartRate) <= self.loLimitAlarm) {
            
            self.hrState = HRState.loAlarm
            
            if playSound && (constantRepeat || !playedAlarm) {
                WKInterfaceDevice.current().play(.failure)
                print("playing sound 3")
                playedAlarm = true
            }
            
        } else {
            self.hrState = HRState.normal
            playedAlarm = false
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
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateRecoveryOneMinute)!
        ]

        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)  { (success, error) in
            if !success {
                // Handle the error here.
                print("Authorisation Failed with error: \(String(describing: error))")
            }
        }
    }

    
    // MARK: - Workout Metrics
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }
        print("In Update for Statistics")
        
        DispatchQueue.main.async {
            print("in DespatchQueue")
                        
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.summaryMetrics.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                self.summaryMetrics.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning), HKQuantityType.quantityType(forIdentifier: .distanceCycling):
                let meterUnit = HKUnit.meter()
                self.summaryMetrics.distance = statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0
            default:
                return
            }
        }
    }

    
}




// MARK: - HKWorkoutSessionDelegate
extension ProfileData: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.running = toState == .running
        }
        
        
        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            builder?.endCollection(withEnd: date) { (success, error) in
                self.builder?.finishWorkout { (workout, error) in
                    DispatchQueue.main.async {
                        self.workout = workout
                    }
                }
            }
        }
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {

    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension ProfileData: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {

    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        
        print("In workoutBuilder")
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }

            let statistics = workoutBuilder.statistics(for: quantityType)

            // Update the published values.
            updateForStatistics(statistics)
            
            print("Updating statistics")
        }
    }
}
