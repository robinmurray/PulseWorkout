//
//  ActivityDataManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 30/06/2023.
//


import Foundation
import CloudKit
import Gzip



func getCacheDirectory() -> URL? {

    let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("pulseWorkout")
    do {
        try FileManager.default.createDirectory(at: cachePath, withIntermediateDirectories: true)
    } catch {
        print("error \(error)")
        return nil
    }

    return cachePath
}


class ActivityRecord: NSObject, Identifiable, Codable, ObservableObject {
    
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

    private var settingsManager: SettingsManager!
    
    init(settingsManager: SettingsManager) {
        super.init()
        self.settingsManager = settingsManager
        
        let baseFileName = NSUUID().uuidString  // base of file name for tcx and json files
        self.tcxFileName = baseFileName + ".gz"
        self.JSONFileName = baseFileName + ".json"

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
    
        recordID = CKRecord.ID()
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
        case name, type, sportType, startDateLocal,
             elapsedTime, pausedTime, movingTime, activityDescription, distanceMeters,
             averageHeartRate, averageCadence, averagePower, averageSpeed, activeEnergy, timeOverHiAlarm, timeUnderLoAlarm, hiHRLimit, loHRLimit, stravaStatus, totalAscent, totalDescent, tcxFileName, JSONFileName
    }
    
    /// Get URL for JSON file
    func CacheURL(fileName: String) -> URL? {

        guard let cachePath = getCacheDirectory() else { return nil }

        return cachePath.appendingPathComponent(fileName)
    }

    /// Write activity record to JSON file in cache folder
    func writeToJSON() -> Bool {
        
        guard let jFile = JSONFileName else { return false }
        guard let jURL = CacheURL(fileName: jFile) else { return false }
        
        print("Writing Activity Record to JSON file")
        do {
            let data = try JSONEncoder().encode(self)
            let jsonString = String(data: data, encoding: .utf8)
            print("JSON : \(String(describing: jsonString))")
            do {
                try data.write(to: jURL)
                
                return true
            }
            catch {
    //            error as any Error
                print("error \(error)")
                return false
            }

        } catch {
            print("Error enconding Activity Record")
            return false
        }

    }

    /// Create activity record from JSON file in cache folder
    func readFromJSON(jURL: URL) -> Bool {

        do {
            let data = try Data(contentsOf: jURL)
            let decoder = JSONDecoder()
            let JSONData = try decoder.decode(ActivityRecord.self, from: data)
            name = JSONData.name
            type = JSONData.type
            sportType = JSONData.sportType
            startDateLocal = JSONData.startDateLocal
            elapsedTime = JSONData.elapsedTime
            pausedTime = JSONData.pausedTime
            movingTime = JSONData.movingTime
            activityDescription = JSONData.activityDescription
            distanceMeters = JSONData.distanceMeters
            averageHeartRate = JSONData.averageHeartRate
            averageCadence = JSONData.averageCadence
            averagePower = JSONData.averagePower
            averageSpeed = JSONData.averageSpeed
            activeEnergy = JSONData.activeEnergy
            timeOverHiAlarm = JSONData.timeOverHiAlarm
            timeUnderLoAlarm = JSONData.timeUnderLoAlarm
            hiHRLimit = JSONData.hiHRLimit
            loHRLimit = JSONData.loHRLimit
            stravaStatus = JSONData.stravaStatus
            totalAscent = JSONData.totalAscent
            totalDescent = JSONData.totalDescent
            tcxFileName = JSONData.tcxFileName
            JSONFileName = JSONData.JSONFileName

            return true
        }
        catch {
            print("error:\(error)")
            return false
        }
    }

    
    /// Remove temporary .json file from cache folder
    func deleteJSON() {
        guard let jFile = JSONFileName else { return }
        guard let jURL = CacheURL(fileName: jFile) else { return }

        do {
            try FileManager.default.removeItem(at: jURL)
                print("JSON file has been deleted")
        } catch {
            print(error)
        }
    }


}


// MARK: - Management of list of track points within ActivityRecord

/// Extension for serialising / de-serialising activity record to JSON file
extension ActivityRecord {
    
    /// Add data as a track point
    func addTrackPoint() {

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
        if !(isPaused && !settingsManager.aveHRPaused) {
            heartRateAnalysis.add(heartRate)
        }
        
        cadenceAnalysis.add(cadence == nil ? nil : Double(cadence!), includeZeros: settingsManager.aveCadenceZeros)
        powerAnalysis.add(cadence == nil ? nil : Double(watts!), includeZeros: settingsManager.avePowerZeros)

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

}

// MARK: - Saving / Receiving Activity Record to / from Cloudkit

/// Extension for Saving / Receiving Activity Record to / from Cloudkit
extension ActivityRecord {
    
    func asCKRecord() -> CKRecord {
        recordID = CKRecord.ID()
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

    }

    
}


// MARK: - ActivityDataManager

class ActivityDataManager: NSObject, ObservableObject {
    
    var container: CKContainer!
    var database: CKDatabase!
    var zoneID: CKRecordZone.ID!
    var settingsManager: SettingsManager
    @Published var isBusy: Bool = false
    @Published var fetched: Bool = false
    @Published var recordSet: [ActivityRecord] = []

    var liveActivityRecord: ActivityRecord?
    var deferredSaveTimer: Timer?

    // Dummy activity record used for previews
    var dummyActivityRecord: ActivityRecord

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        dummyActivityRecord = ActivityRecord(settingsManager: settingsManager)
        super.init()
        
        container = CKContainer(identifier: "iCloud.CloudKitLesson")
        database = container.privateCloudDatabase
        zoneID = CKRecordZone.ID(zoneName: "CKL_Zone")
        /*
        Task {
            do {
                try await createCKZoneIfNeeded()
            } catch {
                print("error \(error)")
            }

        }
         */

        fetchAll()
        
        // if starts and has unsaved records - attenmpt to save
        if deferredSaveRequired() { startDeferredSave() }
    }
    
    /// Start an activity and initiate data collection
    func start(activityProfile: ActivityProfile, startDate: Date) {
        
        liveActivityRecord = ActivityRecord(settingsManager: settingsManager)
        liveActivityRecord?.start(activityProfile: activityProfile, startDate: startDate)
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
            liveActivityRecord!.movingTime = max(liveActivityRecord!.elapsedTime - liveActivityRecord!.pausedTime, 0)

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
    
    func addTrackPoint() {
        if liveActivityRecord != nil {
            liveActivityRecord!.addTrackPoint()
        }
    }
    
    
    private func createCKZoneIfNeeded() async throws {
        print("in create zone")
 //       UserDefaults.standard.set(false, forKey: "zoneCreated")
        guard !UserDefaults.standard.bool(forKey: "zoneCreated") else {
            return
        }

        print("creating zone")
        let newZone = CKRecordZone(zoneID: zoneID)
        _ = try await database.modifyRecordZones(saving: [newZone], deleting: [])

        UserDefaults.standard.set(true, forKey: "zoneCreated")
    }
 
    
    func saveActivityRecord() {

        if liveActivityRecord != nil {
            // First store activity record to local cache for if defered cloudkit operation required
            let activitySavedLocally = liveActivityRecord!.writeToJSON()
            
            saveActivityRecordtoCK(activityRecord: liveActivityRecord!)
            
            // add activity record to live list view whether save to cloudkit successful or not...
            // if unsuccessful will initiate deferred saving, so long as save to JSON worked!
            if activitySavedLocally {
                self.recordSet.insert(self.liveActivityRecord!, at: 0)
            }
            
 //           liveActivityRecord = nil
        }
    }

    
    func saveActivityRecordtoCK(activityRecord: ActivityRecord) {

        let CKRecord = activityRecord.asCKRecord()

        isBusy = true
            
        database.save(CKRecord) { [self] record, error in
            DispatchQueue.main.async {
                if let error = error {
                    switch error {
                    case CKError.accountTemporarilyUnavailable,
                        CKError.networkFailure,
                        CKError.networkUnavailable,
                        CKError.serviceUnavailable,
                        CKError.zoneBusy:
                        
                        print("temporary error - set up retry")
                        self.startDeferredSave()
                        
                    default:
                        print("permanent error - not retrying")
 //                       self.stopDeferredSave()
                    }
                    
                    print("\(error)")
                    self.isBusy = false
                } else {
                    print("Saved")

                    self.isBusy = false
                    activityRecord.deleteTrackRecord()
                    activityRecord.deleteJSON()
                    
                    // set up a deferred save if there are still records to save
                    if self.deferredSaveRequired() {
                        self.startDeferredSave()
                    }
//                    else {
//                        self.stopDeferredSave()
//                    }
                }
            }
        }
        
    }
    
    func deferredSaveRequired() -> Bool {
        
        let jsonPaths = deferredFileList()
        if jsonPaths.count > 0 {
            return true
            
        }
        return false
        
    }
    
    func startDeferredSave() {
        
        if deferredSaveRequired() {
//            if deferredSaveTimer == nil {
                print("starting deferred timer")
                deferredSaveTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(deferredSave), userInfo: nil, repeats: false)
                deferredSaveTimer!.tolerance = 5
                print("Timer initialised")
//            }
        }
    }

    func stopDeferredSave() {
        
        if deferredSaveTimer != nil {
            deferredSaveTimer!.invalidate()
            deferredSaveTimer = nil
        }
    }

    func deferredFileList() -> [URL] {

        let fm = FileManager.default
        guard let cacheDirectory = getCacheDirectory() else { return [] }
        
        do {
            let files = try fm.contentsOfDirectory(atPath: cacheDirectory.path)
            let paths = files.map { cacheDirectory.appendingPathComponent($0) }
            let jsonPaths = paths.filter{ $0.pathExtension == "json" }

            return jsonPaths

        } catch {
            // failed to read directory
            print("Directory search failed!")
            return []

        }
    }
    
    @objc func deferredSave() {
        
        let jsonPaths = deferredFileList()

        if jsonPaths.count > 0 {
            let deferredActivityRecord = ActivityRecord(settingsManager: settingsManager)
            if deferredActivityRecord.readFromJSON(jURL: jsonPaths[0]) {
                print("executing deferred save on \(deferredActivityRecord)")
                saveActivityRecordtoCK(activityRecord: deferredActivityRecord)
            }
        }
//        else {
//            stopDeferredSave()
//        }
    }

    func clearCache() {
        let fm = FileManager.default

        do {
            let files = try fm.contentsOfDirectory(atPath: getCacheDirectory()!.path)
//            let jsonFiles = files.filter{ $0.pathExtension == "json" }
            for file in files {
                let path = getCacheDirectory()!.appendingPathComponent(file)
                do {
                    try FileManager.default.removeItem(at: path)

                } catch {
                    print(error)
                }

                
            }
        } catch {
            print("Directory search failed!")
            // failed to read directory – bad permissions, perhaps?
        }
    }

    func fetchAll() {
        query()
    }
    
    @objc func query() {
        
        isBusy = true
        recordSet = []
        
        let pred = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: "activity", predicate: pred)
        query.sortDescriptors = [sort]

        let operation = CKQueryOperation(query: query)

        operation.desiredKeys = ["name", "type", "sportType", "startDateLocal", "elapsedTime", "pausedTime", "movingTime",
                                 "activityDescription", "distance", "totalAscent", "totalDescent",
                                 "averageHeartRate", "averageCadence", "averagePower", "averageSpeed", "activeEnergy", "timeOverHiAlarm", "timeUnderLoAlarm", "hiHRLimit", "loHRLimit" ]
        operation.resultsLimit = 50
        operation.configuration.timeoutIntervalForRequest = 30


        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                // TODO: Do something with the record that was received.
                let myRecord = ActivityRecord(settingsManager: self.settingsManager)
                myRecord.fromCKRecord(activityRecord: record)
                DispatchQueue.main.async {
                    print("Adding to recordSet : \(myRecord)")
                    self.recordSet.append(myRecord)
                }
                break
                
            case .failure(let error):
                // TODO: Handle per-record failure, perhaps retry fetching it manually in case an asset failed to download or something like that.
                print( "Fetch failed \(String(describing: error))")
                
                break
            }
        }
            
        operation.queryResultBlock = { result in

            switch result {
            case .success:
                // TODO: Yay, the operation was successful, now do something. Perhaps reload your awesome UI.
                //                    self.fetched = true

                for record in self.recordSet {
                    print( record.description() )
                }
                break
                    
            case .failure(let error):

                switch error {
                case CKError.accountTemporarilyUnavailable,
                    CKError.networkFailure,
                    CKError.networkUnavailable,
                    CKError.serviceUnavailable,
                    CKError.zoneBusy:
//                    CKError.notAuthenticated: //REMOVE!!
                    
                    print("temporary query error - set up retry")
                    self.startDeferredQuery()
                    
                default:
                    print("permanent query error - not retrying")
                }
                print( "Fetch failed \(String(describing: error))")
                break
            }
            DispatchQueue.main.async {
                self.isBusy = false
            }
        }
        
        database.add(operation)

    }
    
    func startDeferredQuery() {
        let deferredTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(query), userInfo: nil, repeats: false)
        deferredTimer.tolerance = 5
    }

    
    func delete(recordID: CKRecord.ID) {
        
        print("deleting \(recordID)")
        isBusy = true

        database.delete(withRecordID: recordID) { [weak self] (ckRecordID, error) in

            if let error = error {
                print(error.localizedDescription)
                return
            }
                
            guard let id = ckRecordID else {
                return
            }
            
            DispatchQueue.main.async {
                self?.isBusy = false
                print("deleted \(id)")
                guard let index = self?.recordSet.firstIndex(where: { $0.recordID == recordID }) else {
                    return
                }
                self?.recordSet.remove(at: index)

            }

        }
        
    }

}
