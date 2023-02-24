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

enum HRSource {
    case healthkit, bluetooth
}


struct SummaryMetrics: Codable {
    var duration: Double
    var averageHeartRate: Double
    var heartRateRecovery: Double
    var activeEnergy: Double
    var distance: Double
    var timeOverHiAlarm: Double
    var timeUnderLoAlarm: Double
    
    func put(tag: String){
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(self) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: tag)
        }

    }

    mutating func get(tag: String){
        print("Trying decode SummaryMetrics")
        
        // Initialise empty dictionary
        // try to read from userDefaults in to this - if fails then use defaults
        var metricsDict: [String: Any] = [:]
        
        let metricsJSON: Data =  UserDefaults.standard.object(forKey: tag) as? Data ?? Data()
        let jsonString = String(data: metricsJSON, encoding: .utf8)
        print("Returned data : \(String(describing: jsonString))")
        do {
            metricsDict = try JSONSerialization.jsonObject(with: metricsJSON, options: []) as! [String: Any]
        } catch {
            print("No valid dictionary stored")
        }

        // Read Dictionary or set default values
        duration = (metricsDict["duration"] ?? Double(0)) as! Double
        averageHeartRate = (metricsDict["averageHeartRate"] ?? Double(0)) as! Double
        heartRateRecovery = (metricsDict["heartRateRecovery"] ?? Double(0)) as! Double
        activeEnergy = (metricsDict["activeEnergy"] ?? Double(0)) as! Double
        distance = (metricsDict["distance"] ?? Double(0)) as! Double
        timeOverHiAlarm = (metricsDict["timeOverHiAlarm"] ?? Double(0)) as! Double
        timeUnderLoAlarm = (metricsDict["timeUnderLoAlarm"] ?? Double(0)) as! Double
    }

    mutating func reset() {
        duration = 0
        averageHeartRate = 0
        heartRateRecovery = 0
        activeEnergy = 0
        distance = 0
        timeOverHiAlarm = 0
        timeUnderLoAlarm = 0

    }
}


enum Profile: String, CaseIterable, Identifiable {
    case race, vo2, threshold, aerobic
    var id: Self { self }
}

var profileNames: [String] = ["Race", "VO2 Max", "Threshold", "Aerobic"]


class WorkoutManager: NSObject, ObservableObject {

    @Published var hrState: HRState = HRState.inactive
    @Published var HRMonitorActive: Bool = false
    @Published var appState: AppState = .initial
    @Published var workoutType: HKWorkoutActivityType = HKWorkoutActivityType.cycling
    @Published var workoutLocation: HKWorkoutSessionLocationType = HKWorkoutSessionLocationType.outdoor

    @Published var heartRate: Double = 0
    @Published var distance: Double = 0
   
    @Published var workout: HKWorkout?
    @Published var running = false
    
    @Published var BTHRMConnected: Bool = false
    
    @Published var liveTabSelection: LiveScreenTab = .liveMetrics

    var playedAlarm: Bool = false
    
    var appInBackground = false
    
    var runCount = 0
    var timer: Timer?
    var HRchange: Int = 10
    var runLimit: Int = 50

    var selectedWorkout: HKWorkoutActivityType?

    var bluetoothManager: HRMViewController?
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?


    var activityProfiles = ActivityProfiles()
    @Published var liveActivityProfile: ActivityProfile

    
    @Published var summaryMetrics = SummaryMetrics(
        duration: 0,
        averageHeartRate: 0,
        heartRateRecovery: 0,
        activeEnergy: 0,
        distance: 0,
        timeOverHiAlarm : 0,
        timeUnderLoAlarm: 0
        )

    @Published var lastSummaryMetrics = SummaryMetrics(
        duration: 0,
        averageHeartRate: 0,
        heartRateRecovery: 0,
        activeEnergy: 0,
        distance: 0,
        timeOverHiAlarm : 0,
        timeUnderLoAlarm: 0
        )


    init(profileName: String = ""){
    
        self.liveActivityProfile = activityProfiles.getDefault()
        
        super.init()
        
        lastSummaryMetrics.get(tag: "LastSession")
        self.bluetoothManager = HRMViewController(workoutManager: self)


    }

    func appActive() {
        print("App becoming active")
        if (appInBackground && (appState != .live)) {
            bluetoothManager!.connectKnownDevices()
        }
        appInBackground = false
    }
    
    func appInactive() {
        print("App becoming Inactive")
    }
    
    func appBackground() {
        print("App becoming Background")
        if appState != .live {
            bluetoothManager!.disconnectKnownDevices()
        }
        appInBackground = true
    }
   
    
    func PauseHRMonitor() {
        self.appState = .paused
    }
    
    func RestartHRMonitor() {
        self.appState = .live
    }

    func editOrAddProfile(activityProfile: ActivityProfile) {

        liveActivityProfile = activityProfile
        
        appState = .editProfile

    }

    func writeLiveActivityProfile() {
        
        activityProfiles.updateOrAdd(activityProfile: liveActivityProfile)
        
    }

    func deleteLiveActivityProfile() {
        activityProfiles.remove(activityProfile: liveActivityProfile)

    }
    
    func startWorkout(activityProfile: ActivityProfile) {
        
        liveActivityProfile = activityProfile
        activityProfiles.update(activityProfile: liveActivityProfile)
        
        liveTabSelection = LiveScreenTab.liveMetrics
        
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
        
        if self.liveActivityProfile.lockScreen && !WKInterfaceDevice.current().isWaterLockEnabled {
            Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(delayedEnableWaterLock), userInfo: nil, repeats: false)
        }

    }

    func endWorkout() {
        self.summaryMetrics.duration = self.builder?.elapsedTime(at: Date()) ?? 0
        session?.end()
        
        startStopHRMonitor()
//        self.summaryMetrics.duration = self.workout?.duration ?? 0.0
    }
    
    func resumeWorkout() {
        session?.resume()
        appState = .live
    }
    
    func pauseWorkout() {
        session?.pause()
        appState = .paused
    }
    
    func setHeartRate(heartRate: Double, hrSource: HRSource) {
             
        if BTHRMConnected {
            if hrSource == .bluetooth {
                self.heartRate = heartRate
                
            }
        } else {
            self.heartRate = heartRate

        }
    }
    
    func startStopHRMonitor() {
        
        if !(HRMonitorActive) {
            print("Initialising timer")
            self.runCount = 0
            self.timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
            self.timer!.tolerance = 0.2
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

        if (self.liveActivityProfile.hiLimitAlarmActive) &&
           (Int(self.heartRate) >= self.liveActivityProfile.hiLimitAlarm) {
            
            self.summaryMetrics.timeOverHiAlarm += 2
            self.hrState = HRState.hiAlarm
            
            if (liveActivityProfile.constantRepeat || !playedAlarm) {
                if liveActivityProfile.playSound {
                    WKInterfaceDevice.current().play(.failure)
                    print("playing sound 1")
                }
                if liveActivityProfile.playHaptic {
                    WKInterfaceDevice.current().play(.directionUp)
                    print("playing sound 2")                }

                playedAlarm = true
            }

            
        } else if (self.liveActivityProfile.loLimitAlarmActive) &&
                    (Int(self.heartRate) <= self.liveActivityProfile.loLimitAlarm) {
 
            self.summaryMetrics.timeUnderLoAlarm += 2
            self.hrState = HRState.loAlarm
            
            if liveActivityProfile.playSound && (liveActivityProfile.constantRepeat || !playedAlarm) {
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
                self.setHeartRate( heartRate: statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0,
                                   hrSource: .healthkit )
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
extension WorkoutManager: HKWorkoutSessionDelegate {
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
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
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
