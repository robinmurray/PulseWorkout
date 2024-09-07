//
//  LiveAcivityManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 23/12/2022.
//

import Foundation
import HealthKit
import AVFoundation
import WatchKit
import os

enum HRSource {
    case healthkit, bluetooth
}

enum AppState {
    case initial, live, paused
}


class LiveActivityManager : NSObject, ObservableObject {

//    var locationManager: LocationManager
    
    @Published var hrState: HRState = HRState.inactive
    @Published var appState: AppState = .initial
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

    @Published var liveTabSelection: LiveScreenTab = .liveMetrics

    var alarmRepeatCount: Int = 0
    
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

    var liveActivityRecord: ActivityRecord?
    
    @Published var activityProfiles = ActivityProfiles()
    @Published var liveActivityProfile: ActivityProfile?
    
    var locationManager: LocationManager

    var settingsManager: SettingsManager
    var dataCache: DataCache
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "liveActivityManager")

    init(profileName: String = "",
         locationManager: LocationManager,
         settingsManager: SettingsManager,
         dataCache: DataCache) {

        self.locationManager = locationManager
        self.settingsManager = settingsManager
        self.dataCache = dataCache
        
        
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
        logger.log("App becoming active")
        if (appInBackground && (appState != .live)) {
            bluetoothManager!.connectDevices()
        }
        appInBackground = false
    }
    
    func appInactive() {
        logger.log("App becoming Inactive")
    }
    
    func appBackground() {
        logger.log("App becoming Background")
        if appState != .live {
            bluetoothManager!.disconnectKnownDevices()
        }
        appInBackground = true
    }
   
    /// Return total elapsed time for the activity
    func elapsedTime(at: Date) -> TimeInterval {
        return builder?.elapsedTime(at: at) ?? 0
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

        return max((builder?.elapsedTime(at: at) ?? 0) - (liveActivityRecord?.pausedTime ?? 0)
                - currentPauseDurationAt(at: at), 0)
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
        alarmRepeatCount = 0
        
        let startDate = Date()
        liveActivityRecord = ActivityRecord(settingsManager: settingsManager)
        liveActivityRecord?.start(activityProfile: activityProfile, startDate: startDate)

        startHRMonitor()

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = workoutLocation
        
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

        // Start the workout session and begin data collection.
        
        // If an outdoor activity then start location services
        if activityProfile.workoutLocationId == HKWorkoutSessionLocationType.outdoor.rawValue {
            locationManager.startBGLocationServices(liveActityRecord: liveActivityRecord!)
        }

        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            // The workout has started.
            if !success {
                            // Handle the error here.
                self.logger.error("Workout start Failed with error: \(String(describing: error))")
            } else {
                self.logger.log("Workout Started")
            }
        }

        if self.liveActivityProfile!.lockScreen && !WKInterfaceDevice.current().isWaterLockEnabled {
            Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(delayedEnableWaterLock), userInfo: nil, repeats: false)
        }

    }
    
    func endWorkout() {
        
        // Finished pause if currently paused
        if liveActivityProfile!.workoutLocationId == HKWorkoutSessionLocationType.outdoor.rawValue {
            locationManager.stopLocationSession()
        }

        self.set(elapsedTime: self.builder?.elapsedTime(at: Date()) ?? 0)

        session?.end()
        
        stopHRMonitor()

    }
    
    func resumeWorkout() {
        session?.resume()
        appState = .live
    }
    
    func pauseWorkout() {
        session?.pause()
        appState = .paused
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
        
        let cyclingPower = (powerDict["instantaneousPower"] ?? 0) as? Int ?? 0
        set(watts: cyclingPower)

        
        var cyclingCadence: Int?
        // lastCrankTime is in seconds with a resolution of 1/1024.
        let lastCrankTime = (powerDict["lastCrankEventTime"] ?? 0) as? Int ?? 0
        let cumulativeCrankRevolutions = (powerDict["cumulativeCrankRevolutions"] ?? 0) as? Int ?? 0
        if (lastCrankTime != 0) && (cumulativeCrankRevolutions != 0) {
            if (prevCrankTime != 0) && (prevCrankRevs != 0) {
                let elapsedCrankTime = lastCrankTime - prevCrankTime
                let newCrankRevs = cumulativeCrankRevolutions - prevCrankRevs
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
    
    func startHRMonitor() {
        logger.debug("Initialising timer")
        self.timer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
        self.timer!.tolerance = 0.2
        logger.debug("Timer initialised")
        self.hrState = HRState.normal
        
        self.appState = .live
    }
    
    func stopHRMonitor() {
        logger.debug("stopping timer")
        self.timer?.invalidate()
        self.hrState = HRState.inactive
        self.appState = .initial
    }
    
    @objc func delayedEnableWaterLock() {
        
        WKInterfaceDevice.current().enableWaterLock()
        
    }
    
    
    @objc func fireTimer() {
        
        if self.hrState != HRState.inactive {
            // add a track point for tcx file creation every time timer fires...
            self.addTrackPoint()
            
            let maxAlarmRepeat = (liveActivityProfile!.constantRepeat ? settingsManager.maxAlarmRepeatCount : 1)

            if (self.liveActivityProfile!.hiLimitAlarmActive) &&
               (Int(self.heartRate ?? 0) >= self.liveActivityProfile!.hiLimitAlarm) {
                
                self.increment(timeOverHiAlarm: 2)
                self.hrState = HRState.hiAlarm
                
                if self.alarmRepeatCount < maxAlarmRepeat {
                    if (liveActivityProfile!.playSound || liveActivityProfile!.playHaptic) {
                        WKInterfaceDevice.current().play(settingsManager.hapticType)
                        logger.debug("playing sound 1")
                    }

                    self.alarmRepeatCount += 1
                }

                
            } else if (self.liveActivityProfile!.loLimitAlarmActive) &&
                        (Int(self.heartRate ?? 999) <= self.liveActivityProfile!.loLimitAlarm) {
     
                increment(timeUnderLoAlarm: 2)
                self.hrState = HRState.loAlarm
                
                if (liveActivityProfile!.playSound || liveActivityProfile!.playHaptic) && (self.alarmRepeatCount < maxAlarmRepeat) {
                    WKInterfaceDevice.current().play(settingsManager.hapticType)
                    logger.debug("playing sound 3")
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
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {

    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
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


extension LiveActivityManager {
    
    func addTrackPoint() {
        if liveActivityRecord != nil {
            liveActivityRecord!.addTrackPoint()
        }
    }
    
    func set(heartRate: Double?) {
        if liveActivityRecord != nil {
            liveActivityRecord!.heartRate = heartRate
        }
    }
    
    func set(elapsedTime: Double) {
        if liveActivityRecord != nil {
            liveActivityRecord!.elapsedTime = elapsedTime
            liveActivityRecord!.movingTime = max(elapsedTime - liveActivityRecord!.pausedTime, 0)
            setAverageSpeed()
        }
    }

    private func setAverageSpeed() {
        if liveActivityRecord!.movingTime != 0 {
            liveActivityRecord!.averageSpeed = liveActivityRecord!.distanceMeters / liveActivityRecord!.movingTime
        }
    }
    
    func increment(pausedTime: Double) {
        if liveActivityRecord != nil {
            liveActivityRecord!.pausedTime += pausedTime
//            liveActivityRecord!.movingTime = max(liveActivityRecord!.elapsedTime - liveActivityRecord!.pausedTime, 0)

        }
    }

    func set(watts: Int?) {
        if liveActivityRecord != nil {
            liveActivityRecord!.watts = watts
        }
    }
    
    func set(cadence:Int?) {
        if liveActivityRecord != nil {
            liveActivityRecord!.cadence = cadence
        }
    }
    
    func set(averageHeartRate: Double) {
        if liveActivityRecord != nil {
            liveActivityRecord!.averageHeartRate = averageHeartRate
        }
    }
    
    func set(activeEnergy: Double) {
        if liveActivityRecord != nil {
            liveActivityRecord!.activeEnergy = activeEnergy
        }
    }
    
    func set(distanceMeters: Double) {
        if liveActivityRecord != nil {
            liveActivityRecord!.distanceMeters = distanceMeters
            setAverageSpeed()
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

    func increment(timeOverHiAlarm: Double) {
        if liveActivityRecord != nil {
            liveActivityRecord!.timeOverHiAlarm += timeOverHiAlarm
        }
    }
    
    func increment(timeUnderLoAlarm: Double) {
        if liveActivityRecord != nil {
            liveActivityRecord!.timeUnderLoAlarm += timeUnderLoAlarm
        }
    }

    
}
