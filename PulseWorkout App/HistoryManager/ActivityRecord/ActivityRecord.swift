//
//  ActivityRecord.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 03/12/2023.
//

import Foundation
import CloudKit
import os
import SwiftUI



enum StravaSaveStatus: Int {
    case dontSave = 0
    case toSave = 1
    case saved = 2
}



class ActivityRecord: NSObject, Identifiable, Codable, ObservableObject {
    
    /// stored reference to datacache for storage & retrieval
    var dataCache: DataCache?
    
    /// Apple HK workout type.
    var workoutTypeId: UInt = 1
    
    /// Apple HK workout location.
    var workoutLocationId: Int = 1
    
    var name: String = "Morning Ride"
    var stravaType: String = "Ride"
//    var sportType = "Ride"
    let baseFileName = NSUUID().uuidString  // base of file name for tcx and json files
    
    var startDateLocal: Date = Date()
    var elapsedTime: Double = 0
    var pausedTime: Double = 0
    var movingTime: Double = 0
    var activityDescription: String = ""
    var activeEnergy: Double = 0
    var timeOverHiAlarm: Double = 0
    var timeUnderLoAlarm: Double = 0
    var hiHRLimit: Int?
    var loHRLimit: Int?
    var stravaSaveStatus: Int = StravaSaveStatus.dontSave.rawValue
    var stravaId: Int?          // id of this record in Strava
    var tcxFileName: String?    // Temporary cache file for tcx file
    var JSONFileName: String?   // Temporary cache file for JSON serialisation of activity record
    
    var toSave: Bool = false        // cache status - record still to be saved to CK
    var toDelete: Bool = false      // cache status - record to be deleted from CK (and removed from cache)
    @Published var toSavePublished: Bool = false    // published version of to be saved
    
    
    /// ** Flags describing content of the activity record **
    /// Does the activity record include location data ?
    var hasLocationData: Bool = false
    
    /// Does the activity record include heart rate data?
    var hasHRData: Bool = false
    
    /// Does the activity record include power data?
    var hasPowerData: Bool = false
    
    /// Time between logging data readings
    /// For internally cretaed activities this is set to 2 seconds
    /// For data imported (eg from Strava) it is calculated as the median of the gap from incoming data
    var trackPointGap: Int = ACTIVITY_RECORDING_INTERVAL
    
    /// ** Current values of instantaneous data fields **
    var heartRate: Double?
    var cadence: Int?
    var watts: Int?
    var speed: Double?
    var latitude: Double?
    var longitude: Double?
    var totalAscent: Double?
    var totalDescent: Double?
    var altitudeMeters: Double?
    var distanceMeters: Double = 0
    

    
    /// ** Values set from vlue of user profile parameters at start of activity **
    /// FTP when activity was recorded
    var FTP: Int?
    
    /// Power zones when activity was recorded
    var powerZoneLimits: [Int] = []
    
    /// Threshold heart rate when activity was recorded
    var thesholdHR: Int?
    
    /// Heart rate zones when activity was recorded
    var HRZoneLimits: [Int] = []
    
    
    
    /// ** Values set from analysing the acivity **
    /// Either done batch (at the end of the activity or on import) or incrementally during recording activities.
    
    /// Total Training Stress Score / Training Load
    var TSS: Double?
    
    /// Training load by power zone (using powerZoneLimits)
    var TSSbyPowerZone: [Double] = []
    
    /// Moving time spent in each power zone (using powerZoneLimits)
    var movingTimebyPowerZone: [Double] = []
    
    /// Estimate of TSS using heart rate data
    var estimatedTSSbyHR: Double?
    
    /// Heart rate based estaimate of TSS by HR Zone
    var TSSEstimatebyHRZone: [Double] = []
    
    /// Moving time spent in each HR Zone
    var movingTimebyHRZone: [Double] = []
    
    /// The lowest altitude point
    var loAltitudeMeters: Double?
    
    /// The highest altitude point
    var hiAltitudeMeters: Double?
    
    var averageHeartRate: Double = 0
    var averageCadence: Int = 0
    var averagePower: Int = 0
    var averageSpeed: Double = 0
    var maxHeartRate: Double = 0
    var maxCadence: Int = 0
    var maxPower: Int = 0
    var maxSpeed: Double = 0
    
    
    // Length of segment in seconds to average heart rate over for HRSegmentAverages
    var averageSegmentSize: Int?
    // List of average heart rates per segment (eg 10 minutes)
    var HRSegmentAverages: [Int] = []
    // List of average power output per segment (eg 10 minutes)
    var powerSegmentAverages: [Int] = []
    
    var cadenceSegmentAverages: [Int] = []
    
    
    var autoPause: Bool = true
    var isPaused: Bool = false
    
    // static image of the route map
    var mapSnapshotAsset: CKAsset?
    var mapSnapshotURL: URL?
    var mapSnapshotFileURL: URL?

    @Published var mapSnapshotImage: UIImage?

    // Altitude background image
    @Published var altitudeImage: UIImage?
    var altitudeImageAsset: CKAsset?
    var altitudeImageURL: URL?
    var altitudeImageFileURL: URL?

    
    var settingsManager: SettingsManager?
    
    // tag path during XML parse
    var tagPath: [String] = []
    var parsedTime: Date?

    var heartRateAnalysis: analysedVariable = analysedVariable()
    var cadenceAnalysis: analysedVariable = analysedVariable()
    var powerAnalysis: analysedVariable = analysedVariable()


    
    // fields used for storing to Cloudkit only
    let recordType = "Activity"
    var recordID: CKRecord.ID!
    var recordName: String!
    var tcxAsset: CKAsset?
    
    /// List of track points within the activity record
    var trackPoints: [TrackPoint] = []
   
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "activityRecord")
    
    // Calculated averages
    struct analysedVariable {
        var N: Int = 0
        var total: Double = 0
        var maxVal: Double = 0
        
        var average: Double {
            get {
                N == 0 ? 0 : total / Double(N)
            }
        }
        
        mutating func add( _ newVal: Double?, includeZeros: Bool = true) {
            
            if newVal == nil {return}
            
            if !includeZeros && (newVal == 0) {return}
            
            maxVal = max(newVal!, maxVal)
            N += 1
            total += newVal!
            
        }
    }


    
    // MARK: - End of Properies
    
    
    /// Basic initialiser
    /// Create new activity record - create recordID and recordName
    /// Rest of activity record is blank - used for recording new activity...
    init(settingsManager: SettingsManager) {
        super.init()
        self.settingsManager = settingsManager
        
        
        self.tcxFileName = baseFileName + ".gz"
        self.JSONFileName = baseFileName + ".json"
        self.recordID = CloudKitManager().getCKRecordID()
        self.recordName = self.recordID.recordName
    }
    
    
    /// Initialise activity record from CloudKt record - will have recordID set
    init(fromCKRecord: CKRecord, settingsManager: SettingsManager, fetchtrackData: Bool = true) {
        super.init()
        self.settingsManager = settingsManager
        self.fromCKRecord(activityRecord: fromCKRecord, fetchtrackData: fetchtrackData)
    }
    
    #if os(iOS)
    /// Initialise activity record from strava activity record
    init(fromStravaActivity: StravaActivity, settingsManager: SettingsManager) {
        super.init()
        self.settingsManager = settingsManager
        self.fromStravaActivity(fromStravaActivity)
    }
    #endif
    
    /// Initialise from another Acivity Record and take a deep copy -- NOTE will have same recordID!
    init(fromActivityRecord: ActivityRecord, settingsManager: SettingsManager) {
        super.init()

        self.settingsManager = settingsManager
        recordID = fromActivityRecord.recordID
        recordName = fromActivityRecord.recordName
        name = fromActivityRecord.name
        stravaType = fromActivityRecord.stravaType
        workoutTypeId = fromActivityRecord.workoutTypeId
        workoutLocationId = fromActivityRecord.workoutLocationId
//        sportType = fromActivityRecord.sportType
        startDateLocal = fromActivityRecord.startDateLocal
        elapsedTime = fromActivityRecord.elapsedTime
        pausedTime = fromActivityRecord.pausedTime
        movingTime = fromActivityRecord.movingTime
        activityDescription = fromActivityRecord.activityDescription
        distanceMeters = fromActivityRecord.distanceMeters
        totalAscent = fromActivityRecord.totalAscent
        totalDescent = fromActivityRecord.totalDescent

        averageHeartRate = fromActivityRecord.averageHeartRate
        averageCadence = fromActivityRecord.averageCadence
        averagePower = fromActivityRecord.averagePower
        averageSpeed = fromActivityRecord.averageSpeed
        activeEnergy = fromActivityRecord.activeEnergy
        timeOverHiAlarm = fromActivityRecord.timeOverHiAlarm
        timeUnderLoAlarm = fromActivityRecord.timeUnderLoAlarm
        hiHRLimit = fromActivityRecord.hiHRLimit
        loHRLimit = fromActivityRecord.loHRLimit

        stravaSaveStatus = fromActivityRecord.stravaSaveStatus
        stravaId = fromActivityRecord.stravaId
        trackPointGap = fromActivityRecord.trackPointGap
        
        TSS = fromActivityRecord.TSS
        FTP = fromActivityRecord.FTP
        powerZoneLimits = fromActivityRecord.powerZoneLimits
        TSSbyPowerZone = fromActivityRecord.TSSbyPowerZone
        movingTimebyPowerZone = fromActivityRecord.movingTimebyPowerZone
        
        thesholdHR = fromActivityRecord.thesholdHR
        estimatedTSSbyHR = fromActivityRecord.estimatedTSSbyHR
        HRZoneLimits = fromActivityRecord.HRZoneLimits
        TSSEstimatebyHRZone = fromActivityRecord.TSSEstimatebyHRZone
        movingTimebyHRZone = fromActivityRecord.movingTimebyHRZone
        
        hasLocationData = fromActivityRecord.hasLocationData
        hasHRData = fromActivityRecord.hasHRData
        hasPowerData = fromActivityRecord.hasPowerData
        
        loAltitudeMeters = fromActivityRecord.loAltitudeMeters
        hiAltitudeMeters = fromActivityRecord.hiAltitudeMeters
        
        averageSegmentSize = fromActivityRecord.averageSegmentSize
        HRSegmentAverages = fromActivityRecord.HRSegmentAverages
        powerSegmentAverages = fromActivityRecord.powerSegmentAverages
        cadenceSegmentAverages = fromActivityRecord.cadenceSegmentAverages
        
        setToSave(fromActivityRecord.toSave)

        toDelete = fromActivityRecord.toDelete
        tcxFileName = fromActivityRecord.tcxFileName
        JSONFileName = fromActivityRecord.JSONFileName
        autoPause = fromActivityRecord.autoPause
        
        mapSnapshotURL = fromActivityRecord.mapSnapshotURL
        mapSnapshotImage = fromActivityRecord.mapSnapshotImage
        mapSnapshotAsset = fromActivityRecord.mapSnapshotAsset
        
        altitudeImage = fromActivityRecord.altitudeImage
        altitudeImageURL = fromActivityRecord.altitudeImageURL
        altitudeImageAsset = fromActivityRecord.altitudeImageAsset
        
        // This should take a copy!
        trackPoints = fromActivityRecord.trackPoints
    }

    
    // MARK: - End of Initialisers
    
    
    /// Change status of toSave flag - and set published version in main async thread
    func setToSave( _ newStatus: Bool ) {

        self.toSave = newStatus
        DispatchQueue.main.async{
            self.toSavePublished = newStatus
        }
    }


    
  
    func start(activityProfile: ActivityProfile, startDate: Date) {
    
//        type = "Ride"
//        sportType = "Ride"
        startDateLocal = startDate
        hiHRLimit = activityProfile.hiLimitAlarmActive ? activityProfile.hiLimitAlarm : nil
        loHRLimit = activityProfile.loLimitAlarmActive ? activityProfile.loLimitAlarm : nil
        workoutTypeId = activityProfile.workoutTypeId
        stravaType = activityProfile.stravaType
        workoutLocationId = activityProfile.workoutLocationId
        autoPause = activityProfile.autoPause
        
        var localStartHour = Int(startDateLocal.formatted(
            Date.FormatStyle(timeZone: TimeZone(abbreviation: TimeZone.current.abbreviation() ?? "")!)
                .hour(.defaultDigits(amPM: .omitted))
        )) ?? 0
        
        let AMPM = startDateLocal.formatted(
            Date.FormatStyle(timeZone: TimeZone(abbreviation: TimeZone.current.abbreviation() ?? "")!)
                .hour(.defaultDigits(amPM: .wide)))

        if AMPM.contains("PM") { localStartHour += 12 }
        
        switch localStartHour {
        case 0 ... 4:
            name = "Night " + activityProfile.name

        case 5 ... 11:
            name = "Morning " + activityProfile.name

        case 12 ... 16:
            name = "Afternoon " + activityProfile.name

        case 17 ... 20:
            name = "Evening " + activityProfile.name
            
        case 21 ... 24:
            name = "Night " + activityProfile.name

        default:
            name = "Morning " + activityProfile.name
        }

        activityDescription = ""
    }
    
    
    /// On completion of activity - save activity record
    func save(dataCache: DataCache) {
        addActivityAnalysis()
        if saveTrackRecord() {
            dataCache.add(activityRecord: self)
        }
    }

    
    func description() -> String {
          let mirror = Mirror(reflecting: self)
          
          var str = "\(mirror.subjectType)("
          var first = true
          for (label, value) in mirror.children {
            if let label = label {
              if first {
                first = false
              } else {
                str += ", "
              }
              str += label
              str += ": "
              str += "\(value)"
            }
          }
          str += ")"
          
          return str
        
    }
    
    
    /// Return true / false depending on whether a heart rate trace exists in the tracke points.
    func heartRateTraceExists() -> Bool {
        
        return trackPoints.map( { $0.heartRate ?? 0 } ).max() ?? Double(0) > 0
        
    }
    
    /// Return true / false depending on whether altitude trace exists in the tracke points.
    func altitudeTraceExists() -> Bool {
        
        return trackPoints.map( { $0.altitudeMeters ?? 0 } ).max() ?? Double(0) > 0
        
    }
    
    /// Return true / false depending on whether distance trace exists in the tracke points.
    func distanceTraceExists() -> Bool {
        
        return trackPoints.map( { $0.distanceMeters ?? 0 } ).max() ?? Double(0) > 0
        
    }

    /// Return true / false depending on whether power trace exists in the tracke points.
    func powerTraceExists() -> Bool {
        
        return trackPoints.map( { $0.watts ?? 0 } ).max() ?? 0 > 0
        
    }

    /// Return true / false depending on whether power trace exists in the tracke points.
    func cadenceTraceExists() -> Bool {
        
        return trackPoints.map( { $0.cadence ?? 0 } ).max() ?? 0 > 0
        
    }
     
}




// MARK: - Set Values


extension ActivityRecord {
    

    func set(heartRate: Double?) {

        self.heartRate = heartRate
        self.hasHRData = true
        if (heartRate ?? 0) > maxHeartRate {
            self.maxHeartRate = heartRate ?? 0
        }
    }
    
    func set(elapsedTime: Double) {

        self.elapsedTime = elapsedTime
        movingTime = max(elapsedTime - pausedTime, 0)
        setAverageSpeed()

    }

    private func setAverageSpeed() {
        if movingTime != 0 {
            averageSpeed = distanceMeters / movingTime
        } else {
            averageSpeed = 0
        }
    }
    
    func increment(pausedTime: Double) {

        self.pausedTime += pausedTime
        movingTime = max(elapsedTime - pausedTime, 0)

    }

    func set(watts: Int?) {

        self.watts = watts
        self.hasPowerData = true
        if (watts ?? 0) > maxPower {
            self.maxPower = watts ?? 0
        }

    }
    
    func set(cadence:Int?) {
        
        self.cadence = cadence
        if (cadence ?? 0) > maxCadence {
            self.maxCadence = cadence ?? 0
        }

    }
    
    func set(averageHeartRate: Double) {

        self.averageHeartRate = averageHeartRate

    }
    
    func set(activeEnergy: Double) {
        
        self.activeEnergy = activeEnergy

    }
    
    func set(distanceMeters: Double) {
        
        self.distanceMeters = distanceMeters
        setAverageSpeed()

    }

    func set(speed: Double?) {
        
        self.speed = speed
        if (speed ?? 0) > maxSpeed {
            self.maxSpeed = speed ?? 0
        }

    }
    
    func set(latitude: Double?) {
        
        self.latitude = latitude
        self.hasLocationData = true

    }
    
    func set(longitude: Double?) {
        
        self.longitude = longitude
        self.hasLocationData = true

    }

    func set(totalAscent: Double?) {
        
        self.totalAscent = totalAscent

    }

    func set(totalDescent: Double?) {
        
        self.totalDescent = totalDescent

    }

    func set(altitudeMeters: Double?) {
        
        self.altitudeMeters = altitudeMeters

    }
    
    func set(isPaused: Bool) {
        
        self.isPaused = isPaused

    }

    func increment(timeOverHiAlarm: Double) {
        
        self.timeOverHiAlarm += timeOverHiAlarm

    }
    
    func increment(timeUnderLoAlarm: Double) {
        
        self.timeUnderLoAlarm += timeUnderLoAlarm

    }

    
}
