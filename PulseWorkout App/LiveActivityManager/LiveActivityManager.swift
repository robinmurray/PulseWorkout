//
//  LiveAcivityManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 23/12/2022.
//

import Foundation
import HealthKit
import AVFoundation
#if os(watchOS)
import WatchKit
#endif
import os

enum HRSource {
    case healthkit, bluetooth
}

enum HRState {
    case inactive
    case normal
    case hiAlarm
    case loAlarm
}

enum LiveActivityState {
    case initial, live, paused
}


class LiveActivityManager : NSObject, ObservableObject {

//    var locationManager: LocationManager
    

    @Published var hrState: HRState = HRState.inactive
    @Published var liveActivityState: LiveActivityState = .initial
    @Published var workoutType: HKWorkoutActivityType = HKWorkoutActivityType.cycling
    @Published var workoutLocation: HKWorkoutSessionLocationType = HKWorkoutSessionLocationType.outdoor

    @Published var heartRate: Double?
 //   @Published var distance: Double?
 //   @Published var cyclingPower: Int?
 //   @Published var cyclingCadence: Int?
   
    @Published var workout: HKWorkout?
    @Published var running = false
    
    @Published var BTHRMConnected: Bool = false
    @Published var BTHRMBatteryLevel: Int?
    @Published var BTcyclePowerBatteryLevel: Int?
    @Published var BTcyclePowerConnected: Bool = false

    #if os(watchOS)
    @Published var liveTabSelection: LiveScreenTab = .liveMetrics
    #endif

    var alarmRepeatCount: Int = 0
    
    var prevCrankTime: Int = 0
    var prevCrankRevs: Int = 0
    
    var timer: Timer?
    var HRchange: Int = 10
    var runLimit: Int = 50

    var selectedWorkout: HKWorkoutActivityType?

    var bluetoothManager: BTDevicesController
    
    let healthStore = HKHealthStore()
    #if os(watchOS)
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    #endif
    
    #if os (iOS)
    var builder: HKWorkoutBuilder?
    #endif

    var liveActivityRecord: ActivityRecord?
    
    @Published var activityProfiles = ProfileManager()
    @Published var liveActivityProfile: ActivityProfile?
    
    var locationManager: LocationManager

    var settingsManager: SettingsManager
    var dataCache: DataCache
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "liveActivityManager")

    init(profileName: String = "",
         locationManager: LocationManager,
         bluetoothManager: BTDevicesController,
         settingsManager: SettingsManager,
         dataCache: DataCache) {

        self.locationManager = locationManager
        self.settingsManager = settingsManager
        self.dataCache = dataCache
        self.bluetoothManager = bluetoothManager
        
        super.init()

        self.liveActivityProfile = activityProfiles.profiles[0]

        // Set up call back functions for when required characteristics are read.
        bluetoothManager.setCharacteristicCallback(characteristicCBUUID: heartRateMeasurementCharacteristicCBUUID,
                                                    callback: setBTHeartRate)
        bluetoothManager.setCharacteristicCallback(characteristicCBUUID: cyclingPowerMeasurementCBUUID,
                                                    callback: setCyclingPower)

        // Set up call back functions for when services connect / disconnect.
        bluetoothManager.setServiceConnectCallback(serviceCBUUID: heartRateServiceCBUUID,
                                                    callback: BTHRMServiceConnected)
        bluetoothManager.setServiceConnectCallback(serviceCBUUID: cyclePowerMeterCBUUID,
                                                    callback: BTcyclePowerServiceConnected)

        // Set up call back functions for when services connect / disconnect.
        bluetoothManager.setBatteryLevelCallback(serviceCBUUID: heartRateServiceCBUUID,
                                                  callback: setBTHRMBatteryLevel)
        bluetoothManager.setBatteryLevelCallback(serviceCBUUID: cyclePowerMeterCBUUID,
                                                  callback: setBTcyclePowerMeterBatteryLevel)

    }
    

   
    /// Return total elapsed time for the activity
    func elapsedTime(at: Date) -> TimeInterval {
        #if os(watchOS)
        return builder?.elapsedTime(at: at) ?? 0
        #else
        let startDate = liveActivityRecord?.startDateLocal ?? Date()
        return at.timeIntervalSince(startDate)
        #endif
    }

    /// Return duration of current auto-pause (or zero if not auto-paused)
    func currentPauseDuration() -> TimeInterval {
        return locationManager.currentPauseDuration()
    }

    /// Return duration of current auto-pause (or zero if not auto-paused) at a given date
    func currentPauseDurationAt(at: Date) -> TimeInterval {
        return locationManager.currentPauseDurationAt(at: at)
    }

    /// Return total moving time = elapsed time - total auto-pause - current active auto-pause
    func movingTime(at: Date) -> TimeInterval {

        return max(elapsedTime(at: at) - (liveActivityRecord?.pausedTime ?? 0)
                - currentPauseDurationAt(at: at), 0)
    }
    
    func pausedTime(at: Date) -> TimeInterval {
        return (liveActivityRecord?.pausedTime ?? 0) + currentPauseDurationAt(at: at)
    }
    
    func PauseHRMonitor() {
        self.liveActivityState = .paused
    }
    
    func RestartHRMonitor() {
        self.liveActivityState = .live
    }

    func startWorkout(activityProfile: ActivityProfile) {

        liveActivityProfile = activityProfile
        #if os(watchOS)
        liveTabSelection = LiveScreenTab.liveMetrics
        #endif

        alarmRepeatCount = 0
        
        let startDate = Date()
        liveActivityRecord = ActivityRecord(settingsManager: settingsManager)
        liveActivityRecord?.start(activityProfile: activityProfile, startDate: startDate)


        startRecording()


        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = workoutLocation

#if os(watchOS)
        do {
            session = try HKWorkoutSession( healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            logger.error("Failed to start Workout Session")
            return
        }

        // Setup session and builder.
        session?.delegate = self
        builder?.delegate = self

        // Set the workout builder's data source.
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: configuration)
        
        #elseif os(iOS)
        builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        #endif
        
        
        // Start the workout session and begin data collection.
        
        // If an outdoor activity then start location services
        if activityProfile.workoutLocationId == HKWorkoutSessionLocationType.outdoor.rawValue {
            locationManager.startBGLocationServices(liveActityRecord: liveActivityRecord!)
        }
        #if os(watchOS)
        session?.startActivity(with: startDate)
        #endif
        
        
        builder?.beginCollection(withStart: startDate) { (success, error) in
            // The workout has started.
            if !success {
                            // Handle the error here.
                self.logger.error("Workout start Failed with error: \(String(describing: error))")
            } else {
                self.logger.log("Workout Started")
            }
        }

        

        #if os(watchOS)
        if self.liveActivityProfile!.lockScreen && !WKInterfaceDevice.current().isWaterLockEnabled {
            Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(delayedEnableWaterLock), userInfo: nil, repeats: false)
        }
        #endif

    }
    
    func endWorkout() {
        
        // Finished pause if currently paused
        if liveActivityProfile!.workoutLocationId == HKWorkoutSessionLocationType.outdoor.rawValue {
            locationManager.stopLocationSession()
        }

        self.set(elapsedTime: elapsedTime(at: Date()))

        #if os(watchOS)
        session?.end()
        
        #elseif os(iOS)
        builder?.endCollection(withEnd: Date())  { (success, error) in
            // The workout has started.
            if !success {
                self.logger.error("Workout completion Failed with error: \(String(describing: error))")
                
            } else {
                self.logger.log("Workout Completed")
                if self.settingsManager.saveAppleHealth {
                    self.builder?.finishWorkout { (workout, error) in
                        DispatchQueue.main.async {
                            self.workout = workout
                        }
                    }
                } else {
                    self.builder?.discardWorkout()
                }
            }
        }
        #endif
        
        stopRecording()

    }
    
    func resumeWorkout() {
#if os(watchOS)
        session?.resume()
#endif
        liveActivityState = .live
    }
    
    func pauseWorkout() {
#if os(watchOS)
        session?.pause()
#endif
        liveActivityState = .paused
    }

    func saveLiveActivityRecord() {

        if liveActivityRecord != nil {
            liveActivityRecord!.save(dataCache: dataCache)

        }
    }
    
    func setHeartRate(heartRate: Double, hrSource: HRSource) {
             
        if BTHRMConnected {
            if hrSource == .bluetooth {
                self.heartRate = heartRate
                
            }
        } else {
            self.heartRate = heartRate

        }

        set(heartRate: heartRate)
        
    }
    
    func setBTHeartRate(value: Any) {
        guard let heartRate = value as? Double else {
            logger.error("API misuse - callback should return value that can be cast to Double")
            return
        }
        
        setHeartRate(heartRate: heartRate, hrSource: .bluetooth)
    }

    func BTHRMServiceConnected(connected: Bool) {
        
        logger.debug("Setting BTHRMConnected to \(connected)")
        // Callback function provided to bluetooth manager to notify when HRM service connects/disconnects
        BTHRMConnected = connected
        if !BTHRMConnected {BTHRMBatteryLevel = nil}
    }
    
    func BTcyclePowerServiceConnected(connected: Bool) {
        
        logger.debug("Setting BTcyclePowerConnected to \(connected)")
        // Callback function provided to bluetooth manager to notify when HRM service connects/disconnects
        BTcyclePowerConnected = connected
        if !BTcyclePowerConnected {BTcyclePowerBatteryLevel = nil}
    }
    
    func setBTHRMBatteryLevel(batteryLevel: Int) {
        logger.debug("Setting HR battery level to \(batteryLevel)")
        
        BTHRMBatteryLevel = batteryLevel
    }

    func setCyclingPower(value: Any) {
        guard let powerDict = value as? [String:Any] else {
            logger.error("API misuse - callback should return value that can be cast to dictionary")
            return
        }

        let cyclePowerInst = (powerDict["instantaneousPower"] ?? 0) as? Int ?? 0
        let cyclePower3s = (powerDict["3sPower"] ?? 0) as? Int ?? 0

        set(watts: settingsManager.use3sCyclePower ? cyclePower3s: cyclePowerInst)

        var cyclingCadence: Int?
        // lastCrankTime is in seconds with a resolution of 1/1024.
        let lastCrankTime = (powerDict["lastCrankEventTime"] ?? 0) as? Int ?? 0
        let cumulativeCrankRevolutions = (powerDict["cumulativeCrankRevolutions"] ?? 0) as? Int ?? 0
        if (lastCrankTime != 0) && (cumulativeCrankRevolutions != 0) {
            if (prevCrankTime != 0) && (prevCrankRevs != 0) {
                let elapsedCrankTime = (lastCrankTime >= prevCrankTime) ? (lastCrankTime - prevCrankTime) : lastCrankTime
                let newCrankRevs = (cumulativeCrankRevolutions >= prevCrankRevs) ? (cumulativeCrankRevolutions - prevCrankRevs) : cumulativeCrankRevolutions
                if elapsedCrankTime != 0 {
                    cyclingCadence = Int( 60 * 1024 / elapsedCrankTime) * newCrankRevs
                }
                if newCrankRevs == 0 {
                    cyclingCadence = 0
                }
                
                set(cadence: cyclingCadence)

            }
            
            prevCrankTime = lastCrankTime
            prevCrankRevs = cumulativeCrankRevolutions
        }
            
    }
    
    func setBTcyclePowerMeterBatteryLevel(batteryLevel: Int) {
        logger.debug("Setting PM battery level to \(batteryLevel)")
        
        BTcyclePowerBatteryLevel = batteryLevel
    }
    
    func startRecording() {
        logger.debug("Initialising timer")
        self.timer = Timer.scheduledTimer(timeInterval: Double(ACTIVITY_RECORDING_INTERVAL), target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        self.timer!.tolerance = 0.2
        logger.debug("Timer initialised")
        self.hrState = HRState.normal
        
        self.liveActivityState = .live
    }
    
    func stopRecording() {
        logger.debug("stopping timer")
        self.timer?.invalidate()
        self.hrState = HRState.inactive
        self.liveActivityState = .initial
    }
    
    @objc func delayedEnableWaterLock() {
        #if os(watchOS)
        WKInterfaceDevice.current().enableWaterLock()
        #endif
        
    }
    
    
    @objc func fireTimer() {
        
        if self.hrState != HRState.inactive {
            // add a track point for tcx file creation every time timer fires...

            set(elapsedTime: elapsedTime(at: Date()))
            self.addTrackPoint()
            
            let maxAlarmRepeat = (liveActivityProfile!.constantRepeat ? settingsManager.maxAlarmRepeatCount : 1)

            if (self.liveActivityProfile!.hiLimitAlarmActive) &&
               (Int(self.heartRate ?? 0) >= self.liveActivityProfile!.hiLimitAlarm) {
                
                self.increment(timeOverHiAlarm: 2)
                self.hrState = HRState.hiAlarm
                
                if self.alarmRepeatCount < maxAlarmRepeat {
                    if (liveActivityProfile!.playSound || liveActivityProfile!.playHaptic) {
#if os(watchOS)
                        WKInterfaceDevice.current().play(settingsManager.hapticType)
                        logger.debug("playing sound 1")
#endif
                    }

                    self.alarmRepeatCount += 1
                }

                
            } else if (self.liveActivityProfile!.loLimitAlarmActive) &&
                        (Int(self.heartRate ?? 999) <= self.liveActivityProfile!.loLimitAlarm) {
     
                increment(timeUnderLoAlarm: 2)
                self.hrState = HRState.loAlarm
                
                if (liveActivityProfile!.playSound || liveActivityProfile!.playHaptic) && (self.alarmRepeatCount < maxAlarmRepeat) {
#if os(watchOS)
                    WKInterfaceDevice.current().play(settingsManager.hapticType)
                    logger.debug("playing sound 3")
#endif
                    self.alarmRepeatCount += 1
                }
                
            } else {
                self.hrState = HRState.normal
                self.alarmRepeatCount = 0
            }

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
                self.logger.error("Authorisation Failed with error: \(String(describing: error))")
            }
        }
    }

    
    // MARK: - Workout Metrics
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }
        logger.debug("In Update for Statistics")
        
        DispatchQueue.main.async {
            self.logger.debug("in DespatchQueue")
                        
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.setHeartRate( heartRate: statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0,
                                   hrSource: .healthkit )
                self.set(averageHeartRate: statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0)
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                self.set(activeEnergy: statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0)
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning), HKQuantityType.quantityType(forIdentifier: .distanceCycling):
                let meterUnit = HKUnit.meter()
                self.set(distanceMeters: statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0)

            default:
                return
            }
        }
    }

    
}




// MARK: - HKWorkoutSessionDelegate
extension LiveActivityManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.running = (toState == .running)
        }
        
        #if os(watchOS)
        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            
            if settingsManager.saveAppleHealth {
                builder?.endCollection(withEnd: date) { (success, error) in
                    self.builder?.finishWorkout { (workout, error) in
                        DispatchQueue.main.async {
                            self.workout = workout
                        }
                    }
                }
            } else {
                builder?.discardWorkout()
            }

        }
        #endif
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {

    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
#if os(watchOS)
extension LiveActivityManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {

    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        
        logger.debug("In workoutBuilder")
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }

            let statistics = workoutBuilder.statistics(for: quantityType)

            // Update the published values.
            updateForStatistics(statistics)
            
            logger.debug("Updating statistics")
        }
    }
}
#endif

extension LiveActivityManager {
    
    func addTrackPoint() {
        if liveActivityRecord != nil {
            liveActivityRecord!.addTrackPoint()
        }
    }
    
    func set(heartRate: Double?) {
        if liveActivityRecord != nil {
            liveActivityRecord!.set(heartRate : heartRate)
        }
    }


    func set(elapsedTime: Double) {
        if liveActivityRecord != nil {
            liveActivityRecord!.set(elapsedTime: elapsedTime)
        }
    }

    func set(watts: Int?) {
        if liveActivityRecord != nil {
            liveActivityRecord!.set(watts: watts)
        }
    }
    
    func set(cadence:Int?) {
        if liveActivityRecord != nil {
            liveActivityRecord!.set(cadence: cadence)
        }
    }
    
    func set(averageHeartRate: Double) {
        if liveActivityRecord != nil {
            liveActivityRecord!.set(averageHeartRate: averageHeartRate)
        }
    }
    
    
    func increment(timeOverHiAlarm: Double) {
        if liveActivityRecord != nil {
            liveActivityRecord!.increment(timeOverHiAlarm: timeOverHiAlarm)
        }
    }
    
    func increment(timeUnderLoAlarm: Double) {
        if liveActivityRecord != nil {
            liveActivityRecord!.increment(timeUnderLoAlarm: timeUnderLoAlarm)
        }
    }
    
    func set(distanceMeters: Double) {
        if liveActivityRecord != nil {
            liveActivityRecord!.set(distanceMeters: distanceMeters)
        }
    }
    
    func set(activeEnergy: Double) {
        if liveActivityRecord != nil {
            liveActivityRecord!.set(activeEnergy: activeEnergy)
        }
    }
    
    /*
    
    func increment(pausedTime: Double) {
        if liveActivityRecord != nil {
            liveActivityRecord!.pausedTime += pausedTime
//            liveActivityRecord!.movingTime = max(liveActivityRecord!.elapsedTime - liveActivityRecord!.pausedTime, 0)

        }
    }


    

    

    

    
    func set(distanceMeters: Double) {
        if liveActivityRecord != nil {
//            liveActivityRecord!.distanceMeters = distanceMeters
            setAverageSpeed()
            liveActivityRecord!.set(distanceMeters: distanceMeters)
        }
    }

    func set(speed: Double?) {
        if liveActivityRecord != nil {
            liveActivityRecord!.speed = speed
        }
    }
    
    func set(latitude: Double?) {
        if liveActivityRecord != nil {
            liveActivityRecord!.latitude = latitude
        }
    }
    
    func set(longitude: Double?) {
        if liveActivityRecord != nil {
            liveActivityRecord!.longitude = longitude
        }
    }

    func set(totalAscent: Double?) {
        if liveActivityRecord != nil {
            liveActivityRecord!.totalAscent = totalAscent
        }
    }

    func set(totalDescent: Double?) {
        if liveActivityRecord != nil {
            liveActivityRecord!.totalDescent = totalDescent
        }
    }

    func set(isPaused: Bool) {
        if liveActivityRecord != nil {
            liveActivityRecord!.isPaused = isPaused
        }
    }


*/
    
}
