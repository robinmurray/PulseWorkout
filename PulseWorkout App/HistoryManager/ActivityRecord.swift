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
    case dontSave = 0
    case toSave = 1
    case saved = 2
}


extension ActivityRecord: XMLParserDelegate {
    
    
    func parserDidStartDocument(_ parser: XMLParser) {
        print("Started parsing document")
    }
    
    func parserDidEndDocument(_ parser: XMLParser) {
        print("Ended parsing document : \(trackPoints.count) trackpoints created")
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        tagPath.append(elementName)
        
        switch elementName {
        case "Trackpoint":
            parsedTime = nil
            heartRate = nil
            cadence = nil
            watts = nil
            speed = nil
            latitude = nil
            longitude = nil
            totalAscent = nil
            totalDescent = nil
            altitudeMeters = nil
            distanceMeters = 0
            break
            
        default:
            // Do Nothing!
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        tagPath.removeLast()
        
        switch elementName {
        case "Trackpoint":
            if parsedTime != nil {
                trackPoints.append(TrackPoint(time: parsedTime!,
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
            }
            break
            
        default:
            // Do Nothing!
            break
        }

    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        
        switch tagPath.joined(separator: "/") {
        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/Time":
            // trackPointNode.addValue(name: "Time", value: time.formatted(Date.ISO8601FormatStyle().dateSeparator(.dash)))
//            self.logger.info("* Time : \(string)")
            let dateFormatter = ISO8601DateFormatter ()
            parsedTime = dateFormatter.date(from: string)

//            self.logger.info("* parsedTime : \(self.parsedTime?.timeIntervalSince1970 ?? 0)")

            break
            
        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/DistanceMeters":
            // trackPointNode.addValue(name: "DistanceMeters", value: String(Int(distanceMeters!)))
//            self.logger.info("* DistanceMeters : \(string)")
            distanceMeters = Double(string) ?? 0
            break
            
        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/Cadence":
            // trackPointNode.addValue(name: "Cadence", value: String(cadence!))
//            self.logger.info("* Cadence : \(string)")
            cadence = Int(string)
            break
            
        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/Position/LongitudeDegrees":
//            self.logger.info("* LongitudeDegrees : \(string)")
            longitude = Double(string)
            break
            
        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/Position/LatitudeDegrees":
//            self.logger.info("* LatitudeDegrees : \(string)")
            latitude = Double(string)
            break
            
        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/AltitudeMeters":
            // IS ALTITUDE INTERGER OR NOT!!??
            // trackPointNode.addValue(name: "AltitudeMeters", value: String(format: "%.1f", altitudeMeters!))
//            self.logger.info("* AltitudeMeters : \(string)")
            altitudeMeters = Double(string)
            break

        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/Extensions/TPX/Speed":
            // tpxNode.addValue(name: "Speed", value: String(format: "%.1f", speed!))
//            self.logger.info("* Speed : \(string)")
            speed = Double(string)
            break
            
        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/Extensions/TPX/Watts":
            // tpxNode.addValue(name: "Watts", value: String(watts!))
//            self.logger.info("* Watts : \(string)")
            watts = Int(string)
            break

        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/HeartRateBpm/Value":
              // HRNode.addValue(name: "Value", value: String(Int(heartRate!)))
//            self.logger.info("* HeartRateBpm : \(string)")
            heartRate = Double(string)
            break

            
        default:
            // Do Nothing!
            break
        }
    }
    
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
    
    // Time between logging data readings
    var trackPointGap: Int = ACTIVITY_RECORDING_INTERVAL
    
    var TSS: Double?
    var FTP: Int?
    var powerZoneLimits: [Int] = []
    var TSSbyPowerZone: [Double] = []
    var movingTimebyPowerZone: [Double] = []
    
    var thesholdHR: Int?
    var estimatedTSSbyHR: Double?
    var HRZoneLimits: [Int] = []
    var TSSEstimatebyHRZone: [Double] = []
    var movingTimebyHRZone: [Double] = []
    
    var autoPause: Bool = true
    var isPaused: Bool = false
    
    // static image of the route map
    var mapSnapshotAsset: CKAsset?
    var mapSnapshotURL: URL?
    var mapSnapshotFileURL: URL?

    @Published var mapSnapshotImage: UIImage?

    private var settingsManager: SettingsManager?
    
    // tag path during XML parse
    private var tagPath: [String] = []
    private var parsedTime: Date?

    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "activityRecord")
    
    // Create new activity record - create recordID and recordName
    init(settingsManager: SettingsManager) {
        super.init()
        self.settingsManager = settingsManager
        
        
        self.tcxFileName = baseFileName + ".gz"
        self.JSONFileName = baseFileName + ".json"
        self.recordID = CloudKitManager().getCKRecordID()
        self.recordName = self.recordID.recordName
    }
    
    // Initialise record from CloudKt record - will have recordID set
    init(fromCKRecord: CKRecord, settingsManager: SettingsManager) {
        super.init()
        self.settingsManager = settingsManager
        self.fromCKRecord(activityRecord: fromCKRecord)
    }
    
    #if os(iOS)
    init(fromStravaActivity: StravaActivity, settingsManager: SettingsManager) {
        super.init()
        self.settingsManager = settingsManager
        self.fromStravaActivity(fromStravaActivity)
    }
    #endif
    
    // Initialise from another Acivity Record and take a deep copy -- NOTE will have same recordID!
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
        totalAscent = fromActivityRecord.totalAscent
        totalDescent = fromActivityRecord.totalDescent
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
        
        
        
        setToSave(fromActivityRecord.toSave)

        toDelete = fromActivityRecord.toDelete
        tcxFileName = fromActivityRecord.tcxFileName
        JSONFileName = fromActivityRecord.JSONFileName
        autoPause = fromActivityRecord.autoPause
        
        mapSnapshotURL = fromActivityRecord.mapSnapshotURL
        mapSnapshotImage = fromActivityRecord.mapSnapshotImage
        mapSnapshotAsset = fromActivityRecord.mapSnapshotAsset
        
        // This should take a copy!
        trackPoints = fromActivityRecord.trackPoints
    }
    
    func setToSave( _ newStatus: Bool ) {

        self.toSave = newStatus
        DispatchQueue.main.async{
            self.toSavePublished = newStatus
        }
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

    var trackPoints: [TrackPoint] = []
    
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
        case recordName, name, workoutTypeId, workoutLocationId, stravaType, startDateLocal,
             elapsedTime, pausedTime, movingTime, activityDescription, distanceMeters,
             averageHeartRate, averageCadence, averagePower, averageSpeed, maxHeartRate, maxCadence, maxPower, maxSpeed,
             activeEnergy, timeOverHiAlarm, timeUnderLoAlarm, hiHRLimit, loHRLimit,
             stravaSaveStatus, stravaId, trackPointGap, TSS, FTP, powerZoneLimits, TSSbyPowerZone, movingTimebyPowerZone,
             thesholdHR, estimatedTSSbyHR, HRZoneLimits, TSSEstimatebyHRZone, movingTimebyHRZone,
             totalAscent, totalDescent, tcxFileName, JSONFileName, toSave, toDelete, mapSnapshotURL
    }
    
    
    
    
}


// MARK: - Management of list of track points within ActivityRecord

/// Extension for managing track points
extension ActivityRecord {


    
    /// Add data as a track point
    func addTrackPoint(trackPointTime: Date = Date()) {

        guard let SM = settingsManager else {
            logger.error("Settings manager not set")
            return
        }
               
        trackPoints.append(TrackPoint(time: trackPointTime,
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
        
        averageHeartRate = heartRateAnalysis.average
        averageCadence = Int(cadenceAnalysis.average)
        averagePower = Int(powerAnalysis.average)

    }


    func trackRecordXML() -> XMLDocument {
       
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

        return tcxXMLDoc

    }
    
    func saveTrackRecord() -> Bool {

        // get files for gzipped tcx file
        guard let gzFile = tcxFileName else { return false }
        guard let gzURL = CacheURL(fileName: gzFile) else { return false }
        
        logger.debug("testing file at \(gzURL.path)")
        if FileManager.default.fileExists(atPath: gzURL.path) {
            return true
        }
        logger.debug("file not found!")
        
        do {

            guard let tcxData = trackRecordXML().serialize().data(using: .utf8) else {return false}
            
            let compressedData: Data = try tcxData.gzipped()
            try compressedData.write(to: gzURL)
            return true
        }
        catch {
//            error as any Error
            logger.error("error \(error)")
            return false
        }

    }

    /// Remove temporary .tcx file
    func deleteTrackRecord() {
        guard let tFile = tcxFileName else { return }
        guard let tURL = CacheURL(fileName: tFile) else { return }

        do {
            try FileManager.default.removeItem(at: tURL)
                logger.debug("tcx has been deleted")
        } catch {
            logger.error("error \(error)")
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
        activityRecord["stravaType"] = stravaType as CKRecordValue
        activityRecord["workoutTypeId"] = workoutTypeId as CKRecordValue
        activityRecord["workoutLocationId"] = workoutLocationId as CKRecordValue

//        activityRecord["sportType"] = sportType as CKRecordValue
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
        activityRecord["maxHeartRate"] = maxHeartRate as CKRecordValue
        activityRecord["maxCadence"] = maxCadence as CKRecordValue
        activityRecord["maxPower"] = maxPower as CKRecordValue
        activityRecord["maxSpeed"] = maxSpeed as CKRecordValue

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
        activityRecord["stravaSaveStatus"] = stravaSaveStatus as CKRecordValue
        activityRecord["stravaId"] = stravaId as CKRecordValue?
        activityRecord["trackPointGap"] = trackPointGap as CKRecordValue

        activityRecord["TSS"] = TSS as CKRecordValue?
        activityRecord["FTP"] = FTP as CKRecordValue?
        activityRecord["powerZoneLimits"] = powerZoneLimits as CKRecordValue
        activityRecord["TSSbyPowerZone"] = TSSbyPowerZone as CKRecordValue
        activityRecord["movingTimebyPowerZone"] = movingTimebyPowerZone as CKRecordValue
        
        activityRecord["thesholdHR"] = thesholdHR
        activityRecord["estimatedTSSbyHR"] = estimatedTSSbyHR
        activityRecord["HRZoneLimits"] = HRZoneLimits
        activityRecord["TSSEstimatebyHRZone"] = TSSEstimatebyHRZone
        activityRecord["movingTimebyHRZone"] = movingTimebyHRZone
        
        
        if saveTrackRecord() {
            logger.debug("creating asset!")
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
        stravaType = activityRecord["stravaType"] ?? "Ride" as String
        workoutTypeId = activityRecord["workoutTypeId"] ?? 1 as UInt
        workoutLocationId = activityRecord["workoutLocationId"] ?? 1 as Int
//        sportType = activityRecord["sportType"] ?? "" as String
        startDateLocal = activityRecord["startDateLocal"] ?? Date() as Date
        elapsedTime = activityRecord["elapsedTime"] ?? 0 as Double
        pausedTime = activityRecord["pausedTime"] ?? 0 as Double
        movingTime = activityRecord["movingTime"] ?? 0 as Double
        activityDescription = activityRecord["activityDescription"] ?? "" as String
        distanceMeters = activityRecord["distance"] ?? 0 as Double
        totalAscent = activityRecord["totalAscent"] ?? 0 as Double
        totalDescent = activityRecord["totalDescent"] ?? 0 as Double

        averageHeartRate = activityRecord["averageHeartRate"] ?? 0 as Double
        averageCadence = activityRecord["averageCadence"] ?? 0 as Int
        averagePower = activityRecord["averagePower"] ?? 0 as Int
        averageSpeed = activityRecord["averageSpeed"] ?? 0 as Double
        maxHeartRate = activityRecord["maxHeartRate"] ?? 0 as Double
        maxCadence = activityRecord["maxCadence"] ?? 0 as Int
        maxPower = activityRecord["maxPower"] ?? 0 as Int
        maxSpeed = activityRecord["maxSpeed"] ?? 0 as Double
        activeEnergy = activityRecord["activeEnergy"] ?? 0 as Double
        timeOverHiAlarm = activityRecord["timeOverHiAlarm"] ?? 0 as Double
        timeUnderLoAlarm = activityRecord["timeUnderLoAlarm"] ?? 0 as Double
        hiHRLimit = activityRecord["hiHRLimit"] as Int?
        loHRLimit = activityRecord["loHRLimit"] as Int?
        totalAscent = activityRecord["totalAscent"] as Double?
        totalDescent = activityRecord["totalDescent"] as Double?
        stravaSaveStatus = (activityRecord["stravaSaveStatus"] ?? StravaSaveStatus.dontSave.rawValue) as Int
        stravaId = activityRecord["stravaId"] as Int?
        trackPointGap = activityRecord["trackPointGap"] ?? ACTIVITY_RECORDING_INTERVAL as Int
        
        TSS = activityRecord["TSS"] as Double?
        FTP = activityRecord["FTP"] as Int?
        powerZoneLimits = (activityRecord["powerZoneLimits"] ?? []) as [Int]
        TSSbyPowerZone = (activityRecord["TSSbyPowerZone"] ?? []) as [Double]
        movingTimebyPowerZone = (activityRecord["movingTimebyPowerZone"] ?? []) as [Double]
        
        thesholdHR = activityRecord["thesholdHR"] as Int?
        estimatedTSSbyHR = activityRecord["estimatedTSSbyHR"] as Double?
        HRZoneLimits = (activityRecord["HRZoneLimits"] ?? []) as [Int]
        TSSEstimatebyHRZone = (activityRecord["TSSEstimatebyHRZone"] ?? []) as [Double]
        movingTimebyHRZone = (activityRecord["movingTimebyHRZone"] ?? []) as [Double]
        
        
        mapSnapshotAsset = activityRecord["mapSnapshot"] as CKAsset?
        if mapSnapshotAsset != nil {
            mapSnapshotURL = mapSnapshotAsset!.fileURL
        }

        setToSave(false)
        toDelete = false
        tcxFileName = baseFileName + ".gz"
        JSONFileName = baseFileName + ".json"
        
        if activityRecord["tcx"] != nil {
            self.logger.info("Parsing track data")
            let asset = activityRecord["tcx"]! as CKAsset
            let fileURL = asset.fileURL!
            
            do {
                let tcxZipData = try Data(contentsOf: fileURL)
                self.logger.log("Got tcx data of size \(tcxZipData.count)")
                
                do {
                    let tcxData: Data = try tcxZipData.gunzipped()
                    self.logger.log("Unzipped data to size \(tcxData.count)")
                    
                    let parser = XMLParser(data: tcxData)

                    parser.delegate = self
                    parser.parse()
                } catch {
                    self.logger.error("Unzip failed")
                }
                
//                return data
            } catch {
                self.logger.error("Can't get data at url:\(fileURL)")
            }
        }
        
    }

    
}

// MARK: - Strava Link

extension ActivityRecord {
 
    #if os(iOS)
    func fromStravaActivity(_ stravaActivity: StravaActivity) {

        /*

         "distance" : 24931.4,
         "moving_time" : 4500,
         "elapsed_time" : 4500,
         "total_elevation_gain" : 0,
         "type" : "Ride",
         "sport_type" : "MountainBikeRide",
         "workout_type" : null,
         "id" : 154504250376823,
         "external_id" : "garmin_push_12345678987654321",
         "upload_id" : 987654321234567891234,
         "start_date" : "2018-05-02T12:15:09Z",
         "start_date_local" : "2018-05-02T05:15:09Z",
         "timezone" : "(GMT-08:00) America/Los_Angeles",
         "utc_offset" : -25200,
         "start_latlng" : null,
         "end_latlng" : null,
         "location_city" : null,
         "location_state" : null,
         "location_country" : "United States",
         "achievement_count" : 0,
         "kudos_count" : 3,
         "comment_count" : 1,
         "athlete_count" : 1,
         "photo_count" : 0,
         "map" : {
           "id" : "a12345678987654321",
           "summary_polyline" : null,
           "resource_state" : 2
         },
         "trainer" : true,
         "commute" : false,
         "manual" : false,
         "private" : false,
         "flagged" : false,
         "gear_id" : "b12345678987654321",
         "from_accepted_tag" : false,
         "average_speed" : 5.54,
         "max_speed" : 11,
         "average_cadence" : 67.1,
         "average_watts" : 175.3,
         "weighted_average_watts" : 210,
         "kilojoules" : 788.7,
         "device_watts" : true,
         "has_heartrate" : true,
         "average_heartrate" : 140.3,
         "max_heartrate" : 178,
         "max_watts" : 406,
         "pr_count" : 0,
         "total_photo_count" : 1,
         "has_kudoed" : false,
         "suffer_score" : 82
         
         
         public let id: Int?  // * Need to store StravaId - DONE - note nil/0
         public let resourceState: ResourceState?
         public let externalId: String?
         public let uploadId: Int?
         
         public let highElevation : Double?  // * ADD
         public let lowElevation : Double?  // * ADD

         public let startDate: Date?

         public let map: Map?
         public let trainer: Bool?

         public let workoutType: WorkoutType?


         public let deviceWatts : Bool?
         public let hasHeartRate : Bool?

         */

        self.recordID = CloudKitManager().getCKRecordID()  // *
        self.recordName = self.recordID.recordName      // *
        
        stravaId = stravaActivity.id
        name = stravaActivity.name ?? ""
        stravaType = stravaActivity.type?.rawValue ?? "Ride"
        workoutTypeId = getHKWorkoutActivityType(stravaType).rawValue
        workoutLocationId = getHKWorkoutSessionLocationType(stravaType).rawValue

//        sportType = "Ride" // *
        /* Possible Strava Values
        "AlpineSki", "BackcountrySki", "Badminton", "Canoeing", "Crossfit", "EBikeRide", "Elliptical", "EMountainBikeRide", "Golf", "GravelRide", "Handcycle", "HighIntensityIntervalTraining", "Hike", "IceSkate", "InlineSkate", "Kayaking", "Kitesurf", "MountainBikeRide", "NordicSki", "Pickleball", "Pilates", "Racquetball", "Ride", "RockClimbing", "RollerSki", "Rowing", "Run", "Sail", "Skateboard", "Snowboard", "Snowshoe", "Soccer", "Squash", "StairStepper", "StandUpPaddling", "Surfing", "Swim", "TableTennis", "Tennis", "TrailRun", "Velomobile", "VirtualRide", "VirtualRow", "VirtualRun", "Walk", "WeightTraining", "Wheelchair", "Windsurf", "Workout", "Yoga"
         
         Foot Sports

         Run
         Trail Run
         Walk
         Hike
         Virtual Run
         
         Cycle Sports

         Ride
         Mountain Bike Ride
         Gravel Ride
         E-Bike Ride
         E-Mountain Bike Ride
         Velomobile
         Virtual Ride
         
         
         Water Sports

         Canoe
         Kayak
         Kitesurf
         Rowing
         Stand Up Paddling
         Surf
         Swim
         Windsurf
         
         
         Winter Sports

         Ice Skate
         Alpine Ski
         Backcountry Ski
         Nordic Ski
         Snowboard
         Snowshoe
         
         
         Other Sports:

         Handcycle
         Inline Skate
         Rock Climb
         Roller Ski
         Golf
         Skateboard
         Football (Soccer)
         Wheelchair
         Badminton
         Tennis
         Pickleball
         Crossfit
         Elliptical
         Stair Stepper
         Weight Training
         Yoga
         Workout
         HIIT
         Pilates
         Table Tennis
         Squash
         Racquetball
         */
        
        startDateLocal = stravaActivity.startDateLocal ?? Date()
        elapsedTime = stravaActivity.elapsedTime ?? 0
        pausedTime = (stravaActivity.elapsedTime ?? 0) - (stravaActivity.movingTime ?? 0)
        movingTime = stravaActivity.movingTime ?? 0
        activityDescription = stravaActivity.activityDescription ?? ""
        distanceMeters = stravaActivity.distance ?? 0
        totalAscent = stravaActivity.totalElevationGain
        totalDescent = 0        // *

        averageHeartRate = stravaActivity.averageHeartRate ?? 0
        averageCadence = Int(stravaActivity.averageCadence ?? 0)
        averagePower = Int(stravaActivity.averagePower ?? 0)
        averageSpeed = stravaActivity.averageSpeed ?? 0
        maxPower = Int(stravaActivity.maxPower ?? 0)
        maxSpeed = stravaActivity.maxSpeed ?? 0
        maxHeartRate = stravaActivity.maxHeartRate ?? 0
        
        activeEnergy = stravaActivity.kiloJoules ?? 0 // * UNITS!
        timeOverHiAlarm = 0
        timeUnderLoAlarm = 0
        hiHRLimit = nil
        loHRLimit = nil
        stravaSaveStatus = StravaSaveStatus.saved.rawValue
        stravaType = stravaActivity.sportType ?? "Ride"
        
        setToSave(false)

        toDelete = false
        
        tcxFileName = baseFileName + ".gz"
        JSONFileName = baseFileName + ".json"
        autoPause = true // *
        
        mapSnapshotURL = nil // *
        mapSnapshotImage = nil // *
        mapSnapshotAsset = nil // *
        
        trackPoints = [] // *
    }
    
    
    /// Add trackpoints to activity record derived from strava streams
    func addStreams(_ streams: [StravaSwift.Stream]) {
        var desiredStreamLength: Int?
        var timeStreamPresent = false
        var timeSeries: [Date] = []
        var heartRateSeries: [Double?] = []
        var distanceMetersSeries: [Double?] = []
        var altitudeMetersSeries: [Double?] = []
        var cadenceSeries: [Int?] = []
        var wattsSeries: [Int?] = []
        var speedSeries: [Double?] = []
        var latitudeSeries: [Double?] = []
        var longitudeSeries: [Double?] = []
        
        for stream in streams {
            
            logger.info("Adding stream: \(stream.type?.rawValue ?? "nil")")
            if let streamLength = desiredStreamLength {
                if stream.data?.count != streamLength {
                    logger.error("Streams of different length!")
                    return
                }
            }
            else {
                desiredStreamLength = stream.data?.count
            }
            
            
            switch stream.type?.rawValue ?? "unknown" {
            case "time":
                timeStreamPresent = true
                let timeStream = stream.data!.map({ $0 as? Double ?? 0 })
                timeSeries = timeStream.map({ startDateLocal.addingTimeInterval( $0 ) })
                let timeGaps = zip(timeStream, timeStream.dropFirst()).map({ $1 - $0 })
                logger.info("Time gaps - minimum : \(timeGaps.min() ?? 0) :: maximum \(timeGaps.max() ?? 0)")
                
                // Set trackpoint gap to time difference between items in series (ignoring pauses!)
                trackPointGap = Int(timeGaps.min() ?? 1)
                break
                
            case "distance":
                distanceMetersSeries = stream.data!.map({ $0 as? Double? ?? nil })
                break
                
            case "latlng":
                latitudeSeries = stream.data!.map({ ($0 as? [Double?] ?? [nil, nil])[0] })
                longitudeSeries = stream.data!.map({ ($0 as? [Double?] ?? [nil, nil])[1] })
                break

            case "heartrate":
                heartRateSeries = stream.data!.map({ $0 as? Double? ?? nil })
                break
                
            case "altitude":
                altitudeMetersSeries = stream.data!.map({ $0 as? Double? ?? nil })
                break
                
            case "cadence":
                cadenceSeries = stream.data!.map({ $0 as? Int? ?? nil })
                break
                
            case "watts":
                wattsSeries = stream.data!.map({ $0 as? Int? ?? nil })
                break
                
            case "velocity_smooth":
                speedSeries = stream.data!.map({ $0 as? Double? ?? nil })
                break
                
            default:
                logger.info("Unknown stream type \(stream.seriesType ?? "nil")")
            }
        }

        
        
        if !timeStreamPresent {
            logger.error("No time stream!")
            return
        }
        
        for (index, timepoint) in timeSeries.enumerated() {

            trackPoints.append(TrackPoint(time: timepoint,
                                          heartRate: heartRateSeries.count == desiredStreamLength ? heartRateSeries[index] : nil,
                                          latitude: latitudeSeries.count == desiredStreamLength ? latitudeSeries[index] : nil,
                                          longitude: longitudeSeries.count == desiredStreamLength ? longitudeSeries[index] : nil,
                                          altitudeMeters: altitudeMetersSeries.count == desiredStreamLength ? altitudeMetersSeries[index] : nil,
                                          distanceMeters: distanceMetersSeries.count == desiredStreamLength ? distanceMetersSeries[index] : nil,
                                          cadence: cadenceSeries.count == desiredStreamLength ? cadenceSeries[index] : nil,
                                          speed: speedSeries.count == desiredStreamLength ? speedSeries[index] : nil,
                                          watts: wattsSeries.count == desiredStreamLength ? wattsSeries[index] : nil
                                         )
                                )
        }
        addActivityAnalysis()
        
    }
    #endif
    
    
    func addActivityAnalysis() {
        FTP = 275
        thesholdHR = 154
        
        
        let powerZoneRatios = [0, 0.55, 0.75, 0.9, 1.05, 1.2]
        if let currentFTP = FTP {
            powerZoneLimits = powerZoneRatios.map({ Int(round($0 * Double(currentFTP))) })
        }
        
        let HRZoneRatios = [0, 0.68, 0.83, 0.94, 1.05]
        if let currentThesholdHR = thesholdHR {
            HRZoneLimits = HRZoneRatios.map({ Int(round($0 * Double(currentThesholdHR))) })
        }

        TSS = getTotalTSS()
        TSSEstimatebyHRZone = getTSSEstimatebyHRZone()
        estimatedTSSbyHR = TSSEstimatebyHRZone.reduce(0, +)
        TSSbyPowerZone = getTSSbyPowerZone()
        movingTimebyPowerZone = getmovingTimebyPowerZone()
    }
    
    
    /// Return incremental TSS score for a wattage - taking into account FTP and trackPointGap
    func incrementalTSS(watts: Int?, ftp: Int, seconds: Int) -> Double {
        
        return (100 * pow(((Double(watts ?? 0)) / Double(ftp)), 2) * (Double(seconds) / (60 * 60) ))
        
    }
    
    
    /// Return total TSS for the entire activity
    func getTotalTSS() -> Double? {
        
        guard let currentFTP = FTP else {return nil}
        
        let TSSSeries = trackPoints.map({ incrementalTSS(watts: $0.watts, ftp: currentFTP, seconds: trackPointGap) })

        let thisTSS = TSSSeries.reduce(0, +)

        let roundedTSS = round(thisTSS * 10) / 10
        
        return roundedTSS
        
    }
    
    
    func getTSSEstimatebyHRZone() -> [Double] {
       
        var calcTSSbyHRZone: [Double] = []
        var TSSSeries: [Double]
        
        guard let currentThesholdHR = thesholdHR,
              let currentFTP = FTP else {return []}
        
        for (index, lowerLimit) in HRZoneLimits.enumerated() {
            let power = powerZoneLimits[index+1]
            if index > HRZoneLimits.count - 2 {
                
                let x = trackPoints.filter({($0.heartRate ?? 0) >= Double(lowerLimit)})
                TSSSeries =
                x.map({ _ in incrementalTSS(watts: power, ftp: currentFTP, seconds: trackPointGap) })
                
            } else {
                TSSSeries = trackPoints.filter({(($0.heartRate ?? 0) >= Double(lowerLimit)) && (($0.heartRate ?? 0) < Double(HRZoneLimits[index+1]))})
                    .map({ _ in incrementalTSS(watts: power, ftp: currentFTP, seconds: trackPointGap) })
            }
        
            let thisTSS = TSSSeries.reduce(0, +)
            let roundedTSS = round(thisTSS * 10) / 10
            calcTSSbyHRZone.append(roundedTSS)
        }
        
        return calcTSSbyHRZone
        
    }
    
    
    func getTSSbyPowerZone() -> [Double] {
    
        guard let currentFTP = FTP else {return []}
        
        var calcTSSbyPowerZone: [Double] = []
        var TSSSeries: [Double]
        
        for (index, lowerLimit) in powerZoneLimits.enumerated() {
            
            if index > powerZoneLimits.count - 2 {
                TSSSeries = trackPoints.filter({($0.watts ?? 0) >= lowerLimit})
                    .map({ incrementalTSS(watts: $0.watts, ftp: currentFTP, seconds: trackPointGap) })
                
            } else {
                TSSSeries = trackPoints.filter({(($0.watts ?? 0) >= lowerLimit) && (($0.watts ?? 0) < powerZoneLimits[index+1])})
                    .map({ incrementalTSS(watts: $0.watts, ftp: currentFTP, seconds: trackPointGap) })
            }
            let thisTSS = TSSSeries.reduce(0, +)
            let roundedTSS = round(thisTSS * 10) / 10
            calcTSSbyPowerZone.append(roundedTSS)
        }
        
        return calcTSSbyPowerZone
    }
    
    
    func getmovingTimebyPowerZone() -> [Double] {
    
        guard let currentFTP = FTP else {return []}
        
        var calcMovingTimebyPowerZone: [Double] = []
        var movingTime: Double
        
        for (index, lowerLimit) in powerZoneLimits.enumerated() {
            
            if index > powerZoneLimits.count - 2 {
                movingTime = Double(trackPoints.filter({($0.watts ?? 0) >= lowerLimit}).count * trackPointGap)
                
            } else {
                movingTime = Double(trackPoints.filter({(($0.watts ?? 0) >= lowerLimit) && (($0.watts ?? 0) < powerZoneLimits[index+1])}).count * trackPointGap)

            }

            calcMovingTimebyPowerZone.append(movingTime)
        }
        
        return calcMovingTimebyPowerZone
    }

}



// MARK: - Set Values


extension ActivityRecord {
    

    func set(heartRate: Double?) {

        self.heartRate = heartRate
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
