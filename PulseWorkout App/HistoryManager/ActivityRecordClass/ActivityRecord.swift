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

    
    var settingsManager: SettingsManager?
    
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
    init(fromCKRecord: CKRecord, settingsManager: SettingsManager, fetchtrackData: Bool = true) {
        super.init()
        self.settingsManager = settingsManager
        self.fromCKRecord(activityRecord: fromCKRecord, fetchtrackData: fetchtrackData)
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
             totalAscent, totalDescent, tcxFileName, JSONFileName, toSave, toDelete, mapSnapshotURL,
             hasLocationData, hasHRData, hasPowerData, loAltitudeMeters, hiAltitudeMeters, averageSegmentSize,
             HRSegmentAverages, powerSegmentAverages, cadenceSegmentAverages
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
        
        TSS = (TSS ?? 0) + incrementalTSS(watts: watts, ftp: 275, seconds: ACTIVITY_RECORDING_INTERVAL)

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
        addActivityAnalysis()
        if saveTrackRecord() {
            dataCache.add(activityRecord: self)
        }
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
