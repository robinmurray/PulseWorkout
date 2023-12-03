//
//  ActivityRecord.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 03/12/2023.
//

import Foundation
import Gzip
import CloudKit



class ActivityRecord: NSObject, Identifiable, Codable {
    
    var name: String = "Morning Ride"
    var type: String = "Ride"
    var sportType = "Ride"
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
    var stravaStatus: Bool = false
    var tcxFileName: String?    // Temporary cache file for tcx file
    var JSONFileName: String?   // Temporary cache file for JSON serialisation of activity record
    
    var toSave: Bool = false        // cache status - record still to be saved to CK
    var toDelete: Bool = false      // cache status - record to be deleted from CK (and removed from cache)
    
    // Instantaneous data fields
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
    
    var isPaused: Bool = false

    private var settingsManager: SettingsManager?
    
    // Create new activity record - create recordID and recordName
    init(settingsManager: SettingsManager) {
        super.init()
        self.settingsManager = settingsManager
        
        let baseFileName = NSUUID().uuidString  // base of file name for tcx and json files
        self.tcxFileName = baseFileName + ".gz"
        self.JSONFileName = baseFileName + ".json"
        self.recordID = CKRecord.ID()
        self.recordName = recordID.recordName

    }
    
    // Initialise record from CloudKt record - will have recordID set
    init(fromCKRecord: CKRecord) {
        super.init()
        self.fromCKRecord(activityRecord: fromCKRecord)
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
    
    var heartRateAnalysis: analysedVariable = analysedVariable()
    var cadenceAnalysis: analysedVariable = analysedVariable()
    var powerAnalysis: analysedVariable = analysedVariable()

    var averageHeartRate: Double = 0
    var averageCadence: Double = 0
    var averagePower: Double = 0
    var averageSpeed: Double = 0
    
    
    // fields used for storing to Cloudkit only
    let recordType = "activity"
    var recordID: CKRecord.ID!
    var recordName: String!
    var tcxAsset: CKAsset?
    
    
    struct TrackPoint {
        var time: Date
        var heartRate: Double?
        var latitude: Double?
        var longitude: Double?
        var altitudeMeters: Double?
        var distanceMeters: Double?
        var cadence: Int?
        var speed: Double?
        var watts: Int?
        
        
        func addXMLtoNode(node: XMLElement) {
            let trackPointNode = node.addNode(name: "Trackpoint")
            trackPointNode.addValue(name: "Time", value: time.formatted(Date.ISO8601FormatStyle().dateSeparator(.dash)))

            if ((latitude != nil) && (longitude != nil)) {
                let positionNode = trackPointNode.addNode(name: "Position")
                positionNode.addValue(name: "LatitudeDegrees", value: String(format: "%.7f", latitude!))
                positionNode.addValue(name: "LongitudeDegrees", value: String(format: "%.7f", longitude!))

            }
            if altitudeMeters != nil {
                trackPointNode.addValue(name: "AltitudeMeters", value: String(format: "%.1f", altitudeMeters!))
            }
    
            if heartRate != nil {
                let HRNode = trackPointNode.addNode(name: "HeartRateBpm")
                HRNode.addValue(name: "Value", value: String(Int(heartRate!)))
            }

            if distanceMeters != nil {
                trackPointNode.addValue(name: "DistanceMeters", value: String(Int(distanceMeters!)))
            }

            if altitudeMeters != nil {
                trackPointNode.addValue(name: "AltitudeMeters", value: String(Int(altitudeMeters!)))
            }

            if cadence != nil {
                trackPointNode.addValue(name: "Cadence", value: String(cadence!))
            }
            
            if (speed != nil && (speed ?? -1) > 0) || watts != nil {
                let extNode = trackPointNode.addNode(name: "Extensions")
                let tpxNode = extNode.addNode(name: "TPX", attributes: ["xmlns" : "http://www.garmin.com/xmlschemas/ActivityExtension/v2"])
                if (speed != nil && (speed ?? -1) > 0) {
                    tpxNode.addValue(name: "Speed", value: String(format: "%.1f", speed!))
                }
                if watts != nil {
                    tpxNode.addValue(name: "Watts", value: String(watts!))
                }
                
            }

        }
        
    }

    private var trackPoints: [TrackPoint] = []
    
    
    func start(activityProfile: ActivityProfile, startDate: Date) {
    
        type = "Ride"
        sportType = "Ride"
        startDateLocal = startDate
        hiHRLimit = activityProfile.hiLimitAlarmActive ? activityProfile.hiLimitAlarm : nil
        loHRLimit = activityProfile.loLimitAlarmActive ? activityProfile.loLimitAlarm : nil

        
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
}

// MARK: - Serialise Activity Record to JSON

/// Extension for serialising / de-serialising activity record to JSON file
extension ActivityRecord {

    // set CodingKeys to define which variables are stored to JSON file
    private enum CodingKeys: String, CodingKey {
        case recordName, name, type, sportType, startDateLocal,
             elapsedTime, pausedTime, movingTime, activityDescription, distanceMeters,
             averageHeartRate, averageCadence, averagePower, averageSpeed, activeEnergy, timeOverHiAlarm, timeUnderLoAlarm, hiHRLimit, loHRLimit,
             stravaStatus, totalAscent, totalDescent, tcxFileName, JSONFileName, toSave, toDelete
    }
    
}


// MARK: - Management of list of track points within ActivityRecord

/// Extension for managing track points
extension ActivityRecord {

    /// Get URL for JSON file
    func CacheURL(fileName: String) -> URL? {

        guard let cachePath = getCacheDirectory() else { return nil }

        return cachePath.appendingPathComponent(fileName)
    }
    
    /// Add data as a track point
    func addTrackPoint() {

        guard let SM = settingsManager else {
            print("Settings manager not set")
            return
        }
        
        trackPoints.append(TrackPoint(time: Date(),
                                      heartRate: heartRate,
                                      latitude: latitude,
                                      longitude: longitude,
                                      altitudeMeters: altitudeMeters,
                                      distanceMeters: distanceMeters,
                                      cadence: cadence,
                                      speed: speed,
                                      watts: watts
                                     )
                            )
        if !(isPaused && !SM.aveHRPaused) {
            heartRateAnalysis.add(heartRate)
        }
        
        cadenceAnalysis.add(cadence == nil ? nil : Double(cadence!), includeZeros: SM.aveCadenceZeros)
        powerAnalysis.add(cadence == nil ? nil : Double(watts!), includeZeros: SM.avePowerZeros)

    }


    func saveTrackRecord() -> Bool {

        // get files for gzipped tcx file
        guard let gzFile = tcxFileName else { return false }
        guard let gzURL = CacheURL(fileName: gzFile) else { return false }
        
        print("testing file at \(gzURL.path)")
        if FileManager.default.fileExists(atPath: gzURL.path) {
            return true
        }
        print("file not found!")
        let tcxXMLDoc = XMLDocument()
        
        tcxXMLDoc.addProlog(prolog: "xml version=\"1.0\" encoding=\"UTF-8\"")
        tcxXMLDoc.addComment(comment: "Written by PulseWorkout")

        let tcxNode = tcxXMLDoc.addNode(name: "TrainingCenterDatabase",
                                        attributes: ["xsi:schemaLocation" : "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd",
                                                     "xmlns:ns5" : "http://www.garmin.com/xmlschemas/ActivityGoals/v1",
                                                     "xmlns:ns3" : "http://www.garmin.com/xmlschemas/ActivityExtension/v2",
                                                     "xmlns:ns2" : "http://www.garmin.com/xmlschemas/UserProfile/v2",
                                                     "xmlns" : "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2",
                                                     "xmlns:xsi" : "http://www.w3.org/2001/XMLSchema-instance"
                                                    ])
        let activitiesNode = tcxNode.addNode(name: "Activities")
        let activityNode = activitiesNode.addNode(name: "Activity", attributes: ["Sport" : "Biking"]) // FIX!!
        activityNode.addValue(name: "Id", value: startDateLocal.formatted(Date.ISO8601FormatStyle().dateSeparator(.dash)))
        let lapNode = activityNode.addNode(name: "Lap", attributes: ["StartTime" : startDateLocal.formatted(Date.ISO8601FormatStyle().dateSeparator(.dash))])
        lapNode.addValue(name: "TotalTimeSeconds", value: String(format: "%.1f", elapsedTime))
        lapNode.addValue(name: "DistanceMeters", value: String(format: "%.1f", distanceMeters))
        /// USE Cadence for average cadence, probably extension for power...
        let aveHRNode = lapNode.addNode(name: "AverageHeartRate")
        aveHRNode.addValue(name: "Value", value: String(Int(averageHeartRate)))
        lapNode.addValue(name: "TriggerMethod", value: "Manual")
        let trackNode = lapNode.addNode(name: "Track")
        for trackPoint in trackPoints {
            trackPoint.addXMLtoNode(node: trackNode)
        }
        
        do {
//            try tcxXMLDoc.serialize().write(to: tURL, atomically: true, encoding: .utf8)
            guard let tcxData = tcxXMLDoc.serialize().data(using: .utf8) else {return false}
            
            let compressedData: Data = try tcxData.gzipped()
            try compressedData.write(to: gzURL)
            return true
        }
        catch {
//            error as any Error
            print("error \(error)")
            return false
        }

    }

    /// Remove temporary .tcx file
    func deleteTrackRecord() {
        guard let tFile = tcxFileName else { return }
        guard let tURL = CacheURL(fileName: tFile) else { return }

        do {
            try FileManager.default.removeItem(at: tURL)
                print("tcx has been deleted")
        } catch {
            print(error)
        }
    }
    
    func save(dataCache: DataCache) {
        if saveTrackRecord() {
            dataCache.add(activityRecord: self)
        }
    }

}

// MARK: - Saving / Receiving Activity Record to / from Cloudkit

/// Extension for Saving / Receiving Activity Record to / from Cloudkit
extension ActivityRecord {
    
    func asCKRecord() -> CKRecord {
// !!        recordID = CKRecord.ID()
        let activityRecord = CKRecord(recordType: recordType, recordID: recordID)
        activityRecord["name"] = name as CKRecordValue
        activityRecord["type"] = type as CKRecordValue
        activityRecord["sportType"] = sportType as CKRecordValue
        activityRecord["startDateLocal"] = startDateLocal as CKRecordValue
        activityRecord["elapsedTime"] = elapsedTime as CKRecordValue
        activityRecord["pausedTime"] = pausedTime as CKRecordValue
        activityRecord["movingTime"] = movingTime as CKRecordValue
        activityRecord["activityDescription"] = activityDescription as CKRecordValue
        activityRecord["distance"] = distanceMeters as CKRecordValue

        activityRecord["averageHeartRate"] = averageHeartRate as CKRecordValue
        activityRecord["averageCadence"] = averageCadence as CKRecordValue
        activityRecord["averagePower"] = averagePower as CKRecordValue
        activityRecord["averageSpeed"] = averageSpeed as CKRecordValue
        activityRecord["activeEnergy"] = activeEnergy as CKRecordValue

        activityRecord["totalAscent"] = (totalAscent ?? 0) as CKRecordValue
        activityRecord["totalDescent"] = (totalDescent ?? 0) as CKRecordValue

        activityRecord["timeOverHiAlarm"] = timeOverHiAlarm as CKRecordValue
        activityRecord["timeUnderLoAlarm"] = timeUnderLoAlarm as CKRecordValue
        if hiHRLimit != nil {
            activityRecord["hiHRLimit"] = hiHRLimit! as CKRecordValue
        }
        if loHRLimit != nil {
            activityRecord["loHRLimit"] = loHRLimit! as CKRecordValue
        }

        
        if saveTrackRecord() {
            print("creating asset!")
            guard let tFile = tcxFileName else { return activityRecord }
            guard let tURL = CacheURL(fileName: tFile) else { return activityRecord }
            activityRecord["tcx"] = CKAsset(fileURL: tURL)
        }

        return activityRecord

    }
    
    func fromCKRecord(activityRecord: CKRecord) {
        recordID = activityRecord.recordID
        recordName = recordID.recordName
        name = activityRecord["name"] ?? "" as String
        type = activityRecord["type"] ?? "" as String
        sportType = activityRecord["sportType"] ?? "" as String
        startDateLocal = activityRecord["startDateLocal"] ?? Date() as Date
        elapsedTime = activityRecord["elapsedTime"] ?? 0 as Double
        pausedTime = activityRecord["pausedTime"] ?? 0 as Double
        movingTime = activityRecord["movingTime"] ?? 0 as Double
        activityDescription = activityRecord["activityDescription"] ?? "" as String
        distanceMeters = activityRecord["distance"] ?? 0 as Double
        totalAscent = activityRecord["totalAscent"] ?? 0 as Double
        totalDescent = activityRecord["totalDescent"] ?? 0 as Double

        averageHeartRate = activityRecord["averageHeartRate"] ?? 0 as Double
        averageCadence = activityRecord["averageCadence"] ?? 0 as Double
        averagePower = activityRecord["averagePower"] ?? 0 as Double
        averageSpeed = activityRecord["averageSpeed"] ?? 0 as Double
        activeEnergy = activityRecord["activeEnergy"] ?? 0 as Double
        timeOverHiAlarm = activityRecord["timeOverHiAlarm"] ?? 0 as Double
        timeUnderLoAlarm = activityRecord["timeUnderLoAlarm"] ?? 0 as Double
        hiHRLimit = activityRecord["hiHRLimit"] as Int?
        loHRLimit = activityRecord["loHRLimit"] as Int?
        totalAscent = activityRecord["totalAscent"] as Double?
        totalDescent = activityRecord["totalDescent"] as Double?
        
        toSave = false
        toDelete = false
        tcxFileName = ""
        JSONFileName = ""
        stravaStatus = false

        
    }

    
}

// MARK: - Set Values


extension ActivityRecord {
    

    
    func set(heartRate: Double?) {

        self.heartRate = heartRate
    
    }
    
    func set(elapsedTime: Double) {

        self.elapsedTime = elapsedTime
        movingTime = max(elapsedTime - pausedTime, 0)
        setAverageSpeed()

    }

    private func setAverageSpeed() {
        if movingTime != 0 {
            averageSpeed = distanceMeters / movingTime
        }
    }
    
    func increment(pausedTime: Double) {

        self.pausedTime += pausedTime
        movingTime = max(elapsedTime - pausedTime, 0)

    }

    func set(watts: Int?) {

        self.watts = watts

    }
    
    func set(cadence:Int?) {
        
        self.cadence = cadence

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

    }
    
    func set(latitude: Double?) {
        
        self.latitude = latitude

    }
    
    func set(longitude: Double?) {
        
        self.longitude = longitude

    }

    func set(totalAscent: Double?) {
        
        self.totalAscent = totalAscent

    }

    func set(totalDescent: Double?) {
        
        self.totalDescent = totalDescent

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
