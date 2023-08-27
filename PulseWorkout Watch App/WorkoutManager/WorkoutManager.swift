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

enum AppState {
    case initial, live, paused
}


class WorkoutManager: NSObject, ObservableObject {

    @Published var hrState: HRState = HRState.inactive
    @Published var HRMonitorActive: Bool = false
    @Published var appState: AppState = .initial
    @Published var workoutType: HKWorkoutActivityType = HKWorkoutActivityType.cycling
    @Published var workoutLocation: HKWorkoutSessionLocationType = HKWorkoutSessionLocationType.outdoor

    @Published var heartRate: Double?
    @Published var distance: Double?
    @Published var cyclingPower: Int?
    @Published var cyclingCadence: Int?
   
    @Published var workout: HKWorkout?
    @Published var running = false
    
    @Published var BTHRMConnected: Bool = false
    @Published var BTHRMBatteryLevel: Int?
    @Published var BTcyclePowerBatteryLevel: Int?
    @Published var BTcyclePowerConnected: Bool = false

    @Published var liveTabSelection: LiveScreenTab = .liveMetrics

    var playedAlarm: Bool = false
    
    var appInBackground = false
    
    var prevCrankTime: Int = 0
    var prevCrankRevs: Int = 0
    
    var timer: Timer?
    var HRchange: Int = 10
    var runLimit: Int = 50

    var selectedWorkout: HKWorkoutActivityType?

    var bluetoothManager: BTDevicesController?
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?

    var activityDataManager: ActivityDataManager?
    @Published var activityRecord: ActivityRecord!
    
    @Published var activityProfiles = ActivityProfiles()
    @Published var liveActivityProfile: ActivityProfile?

    init(profileName: String = ""){

        super.init()

        self.liveActivityProfile = activityProfiles.profiles[0]

        self.bluetoothManager = BTDevicesController(requestedServices: nil)

        // Set up call back functions for when required characteristics are read.
        bluetoothManager!.setCharacteristicCallback(characteristicCBUUID: heartRateMeasurementCharacteristicCBUUID,
                                                    callback: setBTHeartRate)
        bluetoothManager!.setCharacteristicCallback(characteristicCBUUID: cyclingPowerMeasurementCBUUID,
                                                    callback: setCyclingPower)

        // Set up call back functions for when services connect / disconnect.
        bluetoothManager!.setServiceConnectCallback(serviceCBUUID: heartRateServiceCBUUID,
                                                    callback: BTHRMServiceConnected)
        bluetoothManager!.setServiceConnectCallback(serviceCBUUID: cyclePowerMeterCBUUID,
                                                    callback: BTcyclePowerServiceConnected)

        // Set up call back functions for when services connect / disconnect.
        bluetoothManager!.setBatteryLevelCallback(serviceCBUUID: heartRateServiceCBUUID,
                                                  callback: setBTHRMBatteryLevel)
        bluetoothManager!.setBatteryLevelCallback(serviceCBUUID: cyclePowerMeterCBUUID,
                                                  callback: setBTcyclePowerMeterBatteryLevel)

    }

    func appActive() {
        print("App becoming active")
        if (appInBackground && (appState != .live)) {
            bluetoothManager!.connectDevices()
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

    func startWorkout(activityProfile: ActivityProfile) {
        
        liveActivityProfile = activityProfile
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
        self.activityRecord = ActivityRecord()

        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            // The workout has started.
            if !success {
                            // Handle the error here.
                print("Workout start Failed with error: \(String(describing: error))")
            } else {
                print("Workout Started")
                self.activityRecord.start(activityProfile: activityProfile, startDate: startDate)
            }
        }
        
        if self.liveActivityProfile!.lockScreen && !WKInterfaceDevice.current().isWaterLockEnabled {
            Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(delayedEnableWaterLock), userInfo: nil, repeats: false)
        }

    }
    
    func endWorkout() {
        self.activityRecord.elapsedTime = self.builder?.elapsedTime(at: Date()) ?? 0
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
    
    func setHeartRate(heartRate: Double, hrSource: HRSource) {
             
        if BTHRMConnected {
            if hrSource == .bluetooth {
                self.heartRate = heartRate
                
            }
        } else {
            self.heartRate = heartRate

        }
        
    }
    
    func setBTHeartRate(value: Any) {
        guard let heartRate = value as? Double else {
            print("API misuse - callback should return value that can be cast to Double")
            return
        }
        
        setHeartRate(heartRate: heartRate, hrSource: .bluetooth)
    }

    func BTHRMServiceConnected(connected: Bool) {
        
        print("Setting BTHRMConnected to \(connected)")
        // Callback function provided to bluetooth manager to notify when HRM service connects/disconnects
        BTHRMConnected = connected
    }
    
    func BTcyclePowerServiceConnected(connected: Bool) {
        
        print("Setting BTcyclePowerConnected to \(connected)")
        // Callback function provided to bluetooth manager to notify when HRM service connects/disconnects
        BTcyclePowerConnected = connected
    }
    
    func setBTHRMBatteryLevel(batteryLevel: Int) {
        print("Setting HR battery level to \(batteryLevel)")
        
        BTHRMBatteryLevel = batteryLevel
    }

    func setCyclingPower(value: Any) {
        guard let powerDict = value as? [String:Any] else {
            print("API misuse - callback should return value that can be cast to dictionary")
            return
        }

        cyclingPower = (powerDict["instantaneousPower"] ?? 0) as? Int ?? 0

        // lastCrankTime is in seconds with a resolution of 1/1024.
        let lastCrankTime = (powerDict["lastCrankEventTime"] ?? 0) as? Int ?? 0
        let cumulativeCrankRevolutions = (powerDict["cumulativeCrankRevolutions"] ?? 0) as? Int ?? 0
        if (lastCrankTime != 0) && (cumulativeCrankRevolutions != 0) {
            if (prevCrankTime != 0) && (prevCrankRevs != 0) {
                let elapsedCrankTime = lastCrankTime - prevCrankTime
                let newCrankRevs = cumulativeCrankRevolutions - prevCrankRevs
                if elapsedCrankTime != 0 {
                    cyclingCadence = Int( 60 * 1024 / elapsedCrankTime) * newCrankRevs
                    print("*********** lastCrankTime \(lastCrankTime)  cadence \(cyclingCadence)")
                }
                if newCrankRevs == 0 {
                    cyclingCadence = 0
                }

            }
            
            prevCrankTime = lastCrankTime
            prevCrankRevs = cumulativeCrankRevolutions
        }
            
    }
    
    func setBTcyclePowerMeterBatteryLevel(batteryLevel: Int) {
        print("Setting PM battery level to \(batteryLevel)")
        
        BTcyclePowerBatteryLevel = batteryLevel
    }
    func startStopHRMonitor() {
        
        if !(HRMonitorActive) {
            print("Initialising timer")
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
            self.appState = .initial
        }
        
    }
    
    @objc func delayedEnableWaterLock() {
        
        WKInterfaceDevice.current().enableWaterLock()
        
    }
    
    
    @objc func fireTimer() {
        
        activityRecord.addTrackPoint(heartRate: heartRate,
                                     distanceMeters: distance,
                                     cadence: cyclingCadence,
                                     speed: nil,
                                     watts: cyclingPower )

        if (self.liveActivityProfile!.hiLimitAlarmActive) &&
           (Int(self.heartRate ?? 0) >= self.liveActivityProfile!.hiLimitAlarm) {
            
            self.activityRecord.timeOverHiAlarm += 2
            self.hrState = HRState.hiAlarm
            
            if (liveActivityProfile!.constantRepeat || !playedAlarm) {
                if liveActivityProfile!.playSound {
                    WKInterfaceDevice.current().play(.failure)
                    print("playing sound 1")
                }
                if liveActivityProfile!.playHaptic {
                    WKInterfaceDevice.current().play(.directionUp)
                    print("playing sound 2")                }

                playedAlarm = true
            }

            
        } else if (self.liveActivityProfile!.loLimitAlarmActive) &&
                    (Int(self.heartRate ?? 999) <= self.liveActivityProfile!.loLimitAlarm) {
 
            self.activityRecord.timeUnderLoAlarm += 2
            self.hrState = HRState.loAlarm
            
            if liveActivityProfile!.playSound && (liveActivityProfile!.constantRepeat || !playedAlarm) {
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
                self.activityRecord.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                self.activityRecord.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning), HKQuantityType.quantityType(forIdentifier: .distanceCycling):
                let meterUnit = HKUnit.meter()
                self.activityRecord.distance = statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0
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
