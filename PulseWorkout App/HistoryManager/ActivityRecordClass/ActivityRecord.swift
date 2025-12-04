//
//  ActivityRecord.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 03/12/2023.
//

import Foundation
import Gzip
import CloudKit
import os
import SwiftUI
import HealthKit
#if os(iOS)
import StravaSwift
#endif

enum StravaSaveStatus: Int {
    case notSaved = 0       // This record not to be saved to strava - offer optional save
    case toSave = 1         // This record should be saved to strava, but has not been saved yet
    case saved = 2          // This record has been uploaded, StravaId has been obtained, record has been updated - completely saved to Strava
    case saving = 3         // This record save process has started, but not yet uploaded...
    case uploaded = 4       // activity has been uploaded to Strava. Got uploadId, but not StravaId
    case gotStravaId = 5    // has been uploaded and stravaId has been retrieved. Not yet updated record
}

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


class ActivityRecord: NSObject, Identifiable, Codable, ObservableObject {
    
    /// stored reference to datacache for storage & retrieval
    var dataCache: DataCache?
    
    /// Apple HK workout type.
    @Published var workoutTypeId: UInt = 1
    
    /// Apple HK workout location.
    @Published var workoutLocationId: Int = 1
    
    @Published var name: String = "Morning Ride"
    @Published var stravaType: String = "Ride"
//    var sportType = "Ride"
    let baseFileName = NSUUID().uuidString  // base of file name for tcx and json files
    
    var startDate: Date = Date()
    var timeZone: TimeZone = TimeZone.current
    var GMTOffset: Int = TimeZone.current.secondsFromGMT()
    var startDateLocal: Date = Date() + Double(TimeZone.current.secondsFromGMT())

    var elapsedTime: Double = 0
    var pausedTime: Double = 0
    var movingTime: Double = 0
    @Published var activityDescription: String = ""
    var activeEnergy: Double = 0
    var timeOverHiAlarm: Double = 0
    var timeUnderLoAlarm: Double = 0
    var hiHRLimit: Int?
    var loHRLimit: Int?
    
    /// Status of saving record to strava - see StravaSaveStatus enum
    @Published var stravaSaveStatus: Int = StravaSaveStatus.notSaved.rawValue
    
    /// id of this record in Strava
    @Published var stravaId: Int?
    
    /// The upload record id for loading to Strava - the upload record is used to pass pack the StravaId
    var stravaUploadId: Int?
    
    
    var tcxFileName: String?    // Temporary cache file for tcx file
    var JSONFileName: String?   // Temporary cache file for JSON serialisation of activity record
    
    var toSave: Bool = false        // cache status - record still to be saved to CK
    var toDelete: Bool = false      // cache status - record to be deleted from CK (and removed from cache)
    @Published var toSavePublished: Bool = false    // published version of to be saved
    
    // Instantaneous data fields
    var heartRate: Double?
    var cadence: Int?
    var watts: Int?
    var speed: Double?
    var latitude: Double?
    var longitude: Double?
    @Published var totalAscent: Double?
    var totalDescent: Double?
    var altitudeMeters: Double?
    var distanceMeters: Double = 0
    
    // Time between logging data readings
    var trackPointGap: Int = ACTIVITY_RECORDING_INTERVAL
    
    var TSS: Double?
    var profileFTP: Int?
    var profilePowerZoneLimits: [Int] = []
    var TSSbyPowerZone: [Double] = []
    var movingTimebyPowerZone: [Double] = []
    var TSSSummable: Double?
    var TSSSummableByPowerZone: [Double] = []
    var intensityFactor: Double?
    var normalisedPower: Double?
    var estimatedVO2Max: Double?
    var profileWeightKG: Double?
    var profileMaxHR: Int?
    var profileRestHR: Int?
    var estimatedEPOC: Double?
    
    var profileThresholdHR: Int?
    var estimatedTSSbyHR: Double?
    var profileHRZoneLimits: [Int] = []
    var TSSEstimatebyHRZone: [Double] = []
    var movingTimebyHRZone: [Double] = []
    
    var hasLocationData: Bool = false
    var hasHRData: Bool = false
    var hasPowerData: Bool = false
    
    var loAltitudeMeters: Double?
    var hiAltitudeMeters: Double?
    
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

    
    let settingsManager: SettingsManager = SettingsManager.shared
    
    // tag path during XML parse
    var tagPath: [String] = []
    var parsedTime: Date?

    
    var heartRateAnalysis: analysedVariable = analysedVariable()
    var cadenceAnalysis: analysedVariable = analysedVariable()
    var powerAnalysis: analysedVariable = analysedVariable()

    var averageHeartRate: Double = 0
    var averageCadence: Int = 0
    var averagePower: Int = 0
    var averageSpeed: Double = 0
    var maxHeartRate: Double = 0
    var maxCadence: Int = 0
    var maxPower: Int = 0
    var maxSpeed: Double = 0
    
    // fields used for storing to Cloudkit only
    let recordType = "Activity"
    var recordID: CKRecord.ID!
    var recordName: String!
    var tcxAsset: CKAsset?
    

    var trackPoints: [TrackPoint] = []
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "activityRecord")
    
    
    // MARK: - Initialisers

    
    required init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        recordName = try container.decode(String.self, forKey: .recordName)
        name = try container.decode(String.self, forKey: .name)
        workoutTypeId = try container.decode(UInt.self, forKey: .workoutTypeId)
        workoutLocationId = try container.decode(Int.self, forKey: .workoutLocationId)
        stravaType = try container.decode(String.self, forKey: .stravaType)
        startDate = try container.decode(Date.self, forKey: .startDate)
        GMTOffset = try container.decode(Int.self, forKey: .GMTOffset)
        let timeZoneStr = try container.decode(String.self, forKey: .timeZone)
        timeZone = TimeZone(identifier: timeZoneStr) ?? TimeZone(identifier: "GMT")!

        startDateLocal = try container.decode(Date.self, forKey: .startDateLocal)
        elapsedTime = try container.decode(Double.self, forKey: .elapsedTime)
        pausedTime = try container.decode(Double.self, forKey: .pausedTime)
        movingTime = try container.decode(Double.self, forKey: .movingTime)
        activityDescription = try container.decode(String.self, forKey: .activityDescription)
        distanceMeters = try container.decode(Double.self, forKey: .distanceMeters)
        averageHeartRate = try container.decode(Double.self, forKey: .averageHeartRate)
        averageCadence = try container.decode(Int.self, forKey: .averageCadence)
        averagePower = try container.decode(Int.self, forKey: .averagePower)
        averageSpeed = try container.decode(Double.self, forKey: .averageSpeed)
        maxHeartRate = try container.decode(Double.self, forKey: .maxHeartRate)
        maxCadence = try container.decode(Int.self, forKey: .maxCadence)
        maxPower = try container.decode(Int.self, forKey: .maxPower)
        maxSpeed = try container.decode(Double.self, forKey: .maxSpeed)
        activeEnergy = try container.decode(Double.self, forKey: .activeEnergy)
        timeOverHiAlarm = try container.decode(Double.self, forKey: .timeOverHiAlarm)
        timeUnderLoAlarm = try container.decode(Double.self, forKey: .timeUnderLoAlarm)
        hiHRLimit = try container.decode(Int?.self, forKey: .hiHRLimit)
        loHRLimit = try container.decode(Int?.self, forKey: .loHRLimit)
        stravaSaveStatus = try container.decode(Int.self, forKey: .stravaSaveStatus)
        stravaId = try container.decode(Int?.self, forKey: .stravaId)
        stravaUploadId = try container.decode(Int?.self, forKey: .stravaUploadId)
        trackPointGap = try container.decode(Int.self, forKey: .trackPointGap)
        TSS = try container.decode(Double?.self, forKey: .TSS)
        profileFTP = try container.decode(Int?.self, forKey: .profileFTP)
        profilePowerZoneLimits = try container.decode([Int].self, forKey: .profilePowerZoneLimits)
        TSSbyPowerZone = try container.decode([Double].self, forKey: .TSSbyPowerZone)
        
        TSSSummable = try container.decode(Double?.self, forKey: .TSSSummable)
        TSSSummableByPowerZone = try container.decode([Double].self, forKey: .TSSSummableByPowerZone)
        intensityFactor = try container.decode(Double?.self, forKey: .intensityFactor)
        normalisedPower = try container.decode(Double?.self, forKey: .normalisedPower)
        estimatedVO2Max = try container.decode(Double?.self, forKey: .estimatedVO2Max)

        profileWeightKG = try container.decode(Double?.self, forKey: .profileWeightKG)
        profileMaxHR = try container.decode(Int?.self, forKey: .profileMaxHR)
        profileRestHR = try container.decode(Int?.self, forKey: .profileRestHR)
        estimatedEPOC = try container.decode(Double?.self, forKey: .estimatedEPOC)

        movingTimebyPowerZone = try container.decode([Double].self, forKey: .movingTimebyPowerZone)
        profileThresholdHR = try container.decode(Int?.self, forKey: .profileThresholdHR)
        estimatedTSSbyHR = try container.decode(Double?.self, forKey: .estimatedTSSbyHR)
        profileHRZoneLimits = try container.decode([Int].self, forKey: .profileHRZoneLimits)
        TSSEstimatebyHRZone = try container.decode([Double].self, forKey: .TSSEstimatebyHRZone)
        movingTimebyHRZone = try container.decode([Double].self, forKey: .movingTimebyHRZone)
        totalAscent = try container.decode(Double?.self, forKey: .totalAscent)
        totalDescent = try container.decode(Double?.self, forKey: .totalDescent)
        tcxFileName = try container.decode(String?.self, forKey: .tcxFileName)
        JSONFileName = try container.decode(String?.self, forKey: .JSONFileName)
        toSave = try container.decode(Bool.self, forKey: .toSave)
        toDelete = try container.decode(Bool.self, forKey: .toDelete)
        mapSnapshotURL = try container.decode(URL?.self, forKey: .mapSnapshotURL)
        hasLocationData = try container.decode(Bool.self, forKey: .hasLocationData)
        hasHRData = try container.decode(Bool.self, forKey: .hasHRData)
        hasPowerData = try container.decode(Bool.self, forKey: .hasPowerData)
        loAltitudeMeters = try container.decode(Double?.self, forKey: .loAltitudeMeters)
        hiAltitudeMeters = try container.decode(Double?.self, forKey: .hiAltitudeMeters)
        averageSegmentSize = try container.decode(Int?.self, forKey: .averageSegmentSize)
        HRSegmentAverages = try container.decode([Int].self, forKey: .HRSegmentAverages)
        powerSegmentAverages = try container.decode([Int].self, forKey: .powerSegmentAverages)
        cadenceSegmentAverages = try container.decode([Int].self, forKey: .cadenceSegmentAverages)

    }
     
     func encode(to encoder: Encoder) throws {

         var container = encoder.container(keyedBy: CodingKeys.self)
         
         try container.encode(recordName, forKey: .recordName)
         try container.encode(name, forKey: .name)
         try container.encode(workoutTypeId, forKey: .workoutTypeId)
         try container.encode(workoutLocationId, forKey: .workoutLocationId)
         try container.encode(stravaType, forKey: .stravaType)
         try container.encode(startDateLocal, forKey: .startDateLocal)
         try container.encode(startDate, forKey: .startDate)
         try container.encode(GMTOffset, forKey: .GMTOffset)
         try container.encode(timeZone.identifier, forKey: .timeZone)

         try container.encode(elapsedTime, forKey: .elapsedTime)
         try container.encode(pausedTime, forKey: .pausedTime)
         try container.encode(movingTime, forKey: .movingTime)
         try container.encode(activityDescription, forKey: .activityDescription)
         try container.encode(distanceMeters, forKey: .distanceMeters)
         try container.encode(averageHeartRate, forKey: .averageHeartRate)
         try container.encode(averageCadence, forKey: .averageCadence)
         try container.encode(averagePower, forKey: .averagePower)
         try container.encode(averageSpeed, forKey: .averageSpeed)
         try container.encode(maxHeartRate, forKey: .maxHeartRate)
         try container.encode(maxCadence, forKey: .maxCadence)
         try container.encode(maxPower, forKey: .maxPower)
         try container.encode(maxSpeed, forKey: .maxSpeed)
         try container.encode(activeEnergy, forKey: .activeEnergy)
         try container.encode(timeOverHiAlarm, forKey: .timeOverHiAlarm)
         try container.encode(timeUnderLoAlarm, forKey: .timeUnderLoAlarm)
         try container.encode(hiHRLimit, forKey: .hiHRLimit)
         try container.encode(loHRLimit, forKey: .loHRLimit)
         try container.encode(stravaSaveStatus, forKey: .stravaSaveStatus)
         try container.encode(stravaId, forKey: .stravaId)
         try container.encode(stravaUploadId, forKey: .stravaUploadId)
         try container.encode(trackPointGap, forKey: .trackPointGap)
         try container.encode(TSS, forKey: .TSS)
         try container.encode(profileFTP, forKey: .profileFTP)
         try container.encode(profilePowerZoneLimits, forKey: .profilePowerZoneLimits)
         try container.encode(TSSbyPowerZone, forKey: .TSSbyPowerZone)
         
         try container.encode(TSSSummable, forKey: .TSSSummable)
         try container.encode(TSSSummableByPowerZone, forKey: .TSSSummableByPowerZone)
         try container.encode(intensityFactor, forKey: .intensityFactor)
         try container.encode(normalisedPower, forKey: .normalisedPower)
         try container.encode(estimatedVO2Max, forKey: .estimatedVO2Max)

         try container.encode(profileWeightKG, forKey: .profileWeightKG)
         try container.encode(profileMaxHR, forKey: .profileMaxHR)
         try container.encode(profileRestHR, forKey: .profileRestHR)
         try container.encode(estimatedEPOC, forKey: .estimatedEPOC)
         
         try container.encode(movingTimebyPowerZone, forKey: .movingTimebyPowerZone)
         try container.encode(profileThresholdHR, forKey: .profileThresholdHR)
         try container.encode(estimatedTSSbyHR, forKey: .estimatedTSSbyHR)
         try container.encode(profileHRZoneLimits, forKey: .profileHRZoneLimits)
         try container.encode(TSSEstimatebyHRZone, forKey: .TSSEstimatebyHRZone)
         try container.encode(movingTimebyHRZone, forKey: .movingTimebyHRZone)
         try container.encode(totalAscent, forKey: .totalAscent)
         try container.encode(totalDescent, forKey: .totalDescent)
         try container.encode(tcxFileName, forKey: .tcxFileName)
         try container.encode(JSONFileName, forKey: .JSONFileName)
         try container.encode(toSave, forKey: .toSave)
         try container.encode(toDelete, forKey: .toDelete)
         try container.encode(mapSnapshotURL, forKey: .mapSnapshotURL)
         try container.encode(hasLocationData, forKey: .hasLocationData)
         try container.encode(hasHRData, forKey: .hasHRData)
         try container.encode(hasPowerData, forKey: .hasPowerData)
         try container.encode(loAltitudeMeters, forKey: .loAltitudeMeters)
         try container.encode(hiAltitudeMeters, forKey: .hiAltitudeMeters)
         try container.encode(averageSegmentSize, forKey: .averageSegmentSize)
         try container.encode(HRSegmentAverages, forKey: .HRSegmentAverages)
         try container.encode(powerSegmentAverages, forKey: .powerSegmentAverages)
         try container.encode(cadenceSegmentAverages, forKey: .cadenceSegmentAverages)
     }
     
    
    
    // Create new activity record - create recordID and recordName
    override init() {
        super.init()
        
        self.tcxFileName = baseFileName + ".gz"
        self.JSONFileName = baseFileName + ".json"
        self.recordID = CloudKitOperation().getCKRecordID()
        self.recordName = self.recordID.recordName
    }
    
    // Initialise record from CloudKt record - will have recordID set
    init(fromCKRecord: CKRecord, fetchtrackData: Bool = true) {
        super.init()

        self.fromCKRecord(activityRecord: fromCKRecord, fetchtrackData: fetchtrackData)
    }
    
    #if os(iOS)
    init(fromStravaActivity: StravaActivity) {
        super.init()
        self.fromStravaActivity(fromStravaActivity)
    }
    #endif
    
    
    
    // Initialise from another Acivity Record and take a deep copy -- NOTE will have same recordID!
    init(fromActivityRecord: ActivityRecord) {
        super.init()

        recordID = fromActivityRecord.recordID
        recordName = fromActivityRecord.recordName
        name = fromActivityRecord.name
        stravaType = fromActivityRecord.stravaType
        workoutTypeId = fromActivityRecord.workoutTypeId
        workoutLocationId = fromActivityRecord.workoutLocationId
//        sportType = fromActivityRecord.sportType
        startDateLocal = fromActivityRecord.startDateLocal
        startDate = fromActivityRecord.startDate
        GMTOffset = fromActivityRecord.GMTOffset
        timeZone = fromActivityRecord.timeZone

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
        stravaUploadId = fromActivityRecord.stravaUploadId
        
        trackPointGap = fromActivityRecord.trackPointGap
        
        TSS = fromActivityRecord.TSS
        profileFTP = fromActivityRecord.profileFTP
        profilePowerZoneLimits = fromActivityRecord.profilePowerZoneLimits
        TSSbyPowerZone = fromActivityRecord.TSSbyPowerZone
        movingTimebyPowerZone = fromActivityRecord.movingTimebyPowerZone

        TSSSummable = fromActivityRecord.TSSSummable
        TSSSummableByPowerZone = fromActivityRecord.TSSSummableByPowerZone
        intensityFactor = fromActivityRecord.intensityFactor
        normalisedPower = fromActivityRecord.normalisedPower
        estimatedVO2Max = fromActivityRecord.estimatedVO2Max
        
        profileWeightKG = fromActivityRecord.profileWeightKG
        profileMaxHR = fromActivityRecord.profileMaxHR
        profileRestHR = fromActivityRecord.profileRestHR
        estimatedEPOC = fromActivityRecord.estimatedEPOC
        
        profileThresholdHR = fromActivityRecord.profileThresholdHR
        estimatedTSSbyHR = fromActivityRecord.estimatedTSSbyHR
        profileHRZoneLimits = fromActivityRecord.profileHRZoneLimits
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
        
        
        altitudeImage = fromActivityRecord.altitudeImage
        altitudeImageURL = fromActivityRecord.altitudeImageURL
        altitudeImageAsset = fromActivityRecord.altitudeImageAsset
        
        // Set published values - ensure in main async thread
        DispatchQueue.main.async {
            self.mapSnapshotURL = fromActivityRecord.mapSnapshotURL
            self.mapSnapshotImage = fromActivityRecord.mapSnapshotImage
            self.mapSnapshotAsset = fromActivityRecord.mapSnapshotAsset

        }
        
        // This should take a copy!
        trackPoints = fromActivityRecord.trackPoints
    }
    
    
    func setToSave( _ newStatus: Bool ) {

        self.toSave = newStatus
        DispatchQueue.main.async{
            self.toSavePublished = newStatus
        }
    }


    func start(activityProfile: ActivityProfile, startDate: Date) {
    
//        type = "Ride"
//        sportType = "Ride"
        self.startDate = startDate
        self.startDateLocal = startDate + Double(GMTOffset)
        hiHRLimit = activityProfile.hiLimitAlarmActive ? activityProfile.hiLimitAlarm : nil
        loHRLimit = activityProfile.loLimitAlarmActive ? activityProfile.loLimitAlarm : nil
        workoutTypeId = activityProfile.workoutTypeId
        stravaType = activityProfile.stravaType
        workoutLocationId = activityProfile.workoutLocationId
        autoPause = activityProfile.autoPause
        
        // Get current FTP settings
        profileFTP = settingsManager.userPowerMetrics.currentFTP
        profilePowerZoneLimits = settingsManager.userPowerMetrics.powerZoneLimits
        
        // Set status to automatically save to strava depending onc configuration options
        stravaSaveStatus = activityProfile.autoSaveToStrava() ? StravaSaveStatus.toSave.rawValue : StravaSaveStatus.notSaved.rawValue
        
        var localStartHour = Int(startDate.formatted(
            Date.FormatStyle(timeZone: TimeZone(abbreviation: TimeZone.current.abbreviation() ?? "")!)
                .hour(.defaultDigits(amPM: .omitted))
        )) ?? 0
        
        let AMPM = startDate.formatted(
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
    
    /// Convert 6 power zones to 3 power ranges.
    /// If no power reading use HR estaimates
    /// If nothing return array of zeros
    func TSSByRangeFromZone() -> [Double] {
        var TSSByRange: [Double] = [0, 0, 0]
        if TSSbyPowerZone.count == 6 {
            TSSByRange[0] = TSSbyPowerZone[0] + TSSbyPowerZone[1]
            TSSByRange[1] = TSSbyPowerZone[2] + TSSbyPowerZone[3]
            TSSByRange[2] = TSSbyPowerZone[4] + TSSbyPowerZone[5]
        }
        if TSSByRange.reduce(0, +) == 0 {
            if TSSEstimatebyHRZone.count == 5 {
                TSSByRange[0] = TSSEstimatebyHRZone[0] + TSSEstimatebyHRZone[1]
                TSSByRange[1] = TSSEstimatebyHRZone[2] + TSSEstimatebyHRZone[3]
                TSSByRange[2] = TSSEstimatebyHRZone[4]
            }
        }
        TSSByRange = TSSByRange.map( {round($0 * 10) / 10} )
        return TSSByRange
    }
 
    func TSSSummableByRangeFromZone() -> [Double] {
        var TSSByRange: [Double] = [0, 0, 0]
        if TSSSummableByPowerZone.count == 6 {
            TSSByRange[0] = TSSSummableByPowerZone[0] + TSSSummableByPowerZone[1]
            TSSByRange[1] = TSSSummableByPowerZone[2] + TSSSummableByPowerZone[3]
            TSSByRange[2] = TSSSummableByPowerZone[4] + TSSSummableByPowerZone[5]
        }
        if TSSByRange.reduce(0, +) == 0 {
            if TSSEstimatebyHRZone.count == 5 {
                TSSByRange[0] = TSSEstimatebyHRZone[0] + TSSEstimatebyHRZone[1]
                TSSByRange[1] = TSSEstimatebyHRZone[2] + TSSEstimatebyHRZone[3]
                TSSByRange[2] = TSSEstimatebyHRZone[4]
            }
        }
        TSSByRange = TSSByRange.map( {round($0 * 10) / 10} )
        return TSSByRange
    }
    
    func TSSOrEstimate() -> Double {
        let ts = TSS ?? 0
        let ets = estimatedTSSbyHR ?? 0
        if ts != 0 {
            return (round(ts * 10) / 10)
        }
        return (round(ets * 10) / 10)
        
    }

    func TSSSummableOrEstimate() -> Double {
        let ts = TSSSummable ?? 0
        let ets = estimatedTSSbyHR ?? 0
        if ts != 0 {
            return (round(ts * 10) / 10)
        }
        return (round(ets * 10) / 10)
        
    }
    
    /// Convert5 heart rate zones to 3  ranges.
    /// If no heart rate, use power reading 
    /// If nothing return array of zeros
    func movingTimebyRangeFromZone() -> [Double] {
        var movingTimebyRange: [Double] = [0, 0, 0]
        if movingTimebyHRZone.count == 5 {
            movingTimebyRange[0] = movingTimebyHRZone[0] + movingTimebyHRZone[1]
            movingTimebyRange[1] = movingTimebyHRZone[2] + movingTimebyHRZone[3]
            movingTimebyRange[2] = movingTimebyHRZone[4]
        }
        if movingTimebyRange.reduce(0, +) == 0 {
            if movingTimebyPowerZone.count == 6 {
                movingTimebyRange[0] = movingTimebyPowerZone[0] + movingTimebyPowerZone[1]
                movingTimebyRange[1] = movingTimebyPowerZone[2] + movingTimebyPowerZone[3]
                movingTimebyRange[2] = movingTimebyPowerZone[4] + movingTimebyPowerZone[5]
            }
        }
        movingTimebyRange = movingTimebyRange.map( {round($0 * 10) / 10} )

        return movingTimebyRange
        
    }
    
}

// MARK: - Serialise Activity Record to JSON

/// Extension for serialising / de-serialising activity record to JSON file
extension ActivityRecord {

    // set CodingKeys to define which variables are stored to JSON file
    private enum CodingKeys: String, CodingKey {
        case recordName, name, workoutTypeId, workoutLocationId, stravaType, startDateLocal, startDate, GMTOffset, timeZone,
             elapsedTime, pausedTime, movingTime, activityDescription, distanceMeters,
             averageHeartRate, averageCadence, averagePower, averageSpeed, maxHeartRate, maxCadence, maxPower, maxSpeed,
             activeEnergy, timeOverHiAlarm, timeUnderLoAlarm, hiHRLimit, loHRLimit,
             stravaSaveStatus, stravaId, stravaUploadId, trackPointGap, TSS, movingTimebyPowerZone, TSSbyPowerZone,
             TSSSummable, TSSSummableByPowerZone, intensityFactor, normalisedPower, estimatedVO2Max,
             profileWeightKG, profileMaxHR, profileRestHR, profileFTP, profilePowerZoneLimits, profileThresholdHR, profileHRZoneLimits,
             estimatedEPOC, estimatedTSSbyHR, TSSEstimatebyHRZone, movingTimebyHRZone,
             totalAscent, totalDescent, tcxFileName, JSONFileName, toSave, toDelete, mapSnapshotURL,
             hasLocationData, hasHRData, hasPowerData, loAltitudeMeters, hiAltitudeMeters, averageSegmentSize,
             HRSegmentAverages, powerSegmentAverages, cadenceSegmentAverages
    }
    
}


// MARK: - Activity record status functions

extension ActivityRecord {
 
    
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
