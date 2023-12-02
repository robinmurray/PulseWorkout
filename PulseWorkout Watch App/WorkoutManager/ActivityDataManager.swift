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


class DataCache: NSObject, Codable {
    
    var container: CKContainer!
    var database: CKDatabase!
    var zoneID: CKRecordZone.ID!
    
    // Callback function to update UI if/when cache changes
    var activityDataManager: ActivityDataManager?
    
    let cacheSize = 50
    let cacheFile = "activityCache.act"
    private var activities: [ActivityRecord] = []
    private var refreshList: [ActivityRecord] = []
    private var synchTimer: Timer?
   
    // set CodingKeys to define which variables are stored to JSON file
    private enum CodingKeys: String, CodingKey {
        case activities
    }

    init(readCache: Bool = true) {

        super.init()
        
        container = CKContainer(identifier: "iCloud.CloudKitLesson")
        database = container.privateCloudDatabase
        zoneID = CKRecordZone.ID(zoneName: "CKL_Zone")
        
        
        Task {
            do {
                try await createCKZoneIfNeeded()
            } catch {
                print("error \(error)")
            }

        }
        

        if readCache {
            _ = read()
            
            
            if !dirty() {
                refresh()
            }
        }
        
        synchTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(synch), userInfo: nil, repeats: true)
        synchTimer!.tolerance = 5

    }

    func setActivityDataManager( activityDataManager: ActivityDataManager ) {
        self.activityDataManager = activityDataManager
    }
    
    private func createCKZoneIfNeeded() async throws {

        guard !UserDefaults.standard.bool(forKey: "zoneCreated") else {
            return
        }

        print("creating zone")
        let newZone = CKRecordZone(zoneID: zoneID)
        _ = try await database.modifyRecordZones(saving: [newZone], deleting: [])

        UserDefaults.standard.set(true, forKey: "zoneCreated")
    }
 

    func add(activityRecord: ActivityRecord) {
        
        activityRecord.toSave = true
        activities.insert(activityRecord, at: 0)
        
        if cache().count > cacheSize {
            activities.removeLast()
        }
        
        _ = write()

    }
    
    func delete(recordID: CKRecord.ID) {
               
        guard let index = activities.firstIndex(where: { $0.recordName == recordID.recordName }) else {
            print("DELETION not Found!! ")
            return
        }

        activities[index].toDelete = true
        activities[index].deleteTrackRecord()
        
        print("DELETED OK :\(index) \(recordID.recordName)")
        _ = write()
        
    }
    
    /// Remove item from cache - call once deleted from cloudkit
    func remove(recordID: CKRecord.ID) {
        
        guard let index = activities.firstIndex(where: { $0.recordName == recordID.recordName }) else {
            return
        }

        activities.remove(at: index)
        
        _ = write()
        
    }

    /// Returns list of to-be-saved activity records
    func toBeSaved() -> [ActivityRecord] {
        
        return activities.filter{ ($0.toSave == true) && ($0.toDelete == false) }

    }

    /// Returns list of to-be-deleted activity records
    func toBeDeleted() -> [ActivityRecord] {
        
        return activities.filter{ $0.toDelete == true }

    }
    
    func cache() -> [ActivityRecord] {
        
        return activities.filter{ $0.toDelete == false }
        
    }
    
    /// Does the cache have outstanding additions or deletions to be written to CloudKit?
    func dirty() -> Bool {
        
        return (toBeSaved().count > 0) || (toBeDeleted().count > 0)
        
    }
    
    /// Get URL for JSON file
    func CacheURL(fileName: String) -> URL? {

        guard let cachePath = getCacheDirectory() else { return nil }

        return cachePath.appendingPathComponent(fileName)
    }


    /// Read cache from JSON file in cache folder
    func read() -> Bool {

        guard let cacheURL = CacheURL(fileName: cacheFile) else { return false }

        do {
            let data = try Data(contentsOf: cacheURL)
            let decoder = JSONDecoder()
            let JSONData = try decoder.decode(DataCache.self, from: data)
            activities = []
            
            for activity in JSONData.activities {
                print("activity \(activity.recordName ?? "xxx")  toBeSaved status \(activity.toSave) -- toDelete status \(activity.toDelete)")
                // create recordID from recordName as recordID not serialised to JSON
                activity.recordID = CKRecord.ID(recordName: activity.recordName, zoneID: zoneID)
                activities.append(activity)
            }
            
            return true
        }
        catch {
            print("error:\(error)")
            return false
        }
    }
    
    
    /// Write entire cache to JSON file in cache folder
    func write() -> Bool {
        
        guard let cacheURL = CacheURL(fileName: cacheFile) else { return false }
        
        print("Writing cache to JSON file")
        print("Activities \(activities)")
        do {
            let data = try JSONEncoder().encode(self)
//            let jsonString = String(data: data, encoding: .utf8)
//            print("JSON : \(String(describing: jsonString))")
            do {
                try data.write(to: cacheURL)
                
                if activityDataManager != nil {
                    activityDataManager!.updateUI()
                }

                return true
            }
            catch {
                print("error \(error)")
                return false
            }

        } catch {
            print("Error enconding cache")
            return false
        }

    }

    
    @objc func refresh() {
        
        refreshList = []
        let pred = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: "activity", predicate: pred)
        query.sortDescriptors = [sort]

        let operation = CKQueryOperation(query: query)

        operation.desiredKeys = ["name", "type", "sportType", "startDateLocal", "elapsedTime", "pausedTime", "movingTime",
                                 "activityDescription", "distance", "totalAscent", "totalDescent",
                                 "averageHeartRate", "averageCadence", "averagePower", "averageSpeed", "activeEnergy", "timeOverHiAlarm", "timeUnderLoAlarm", "hiHRLimit", "loHRLimit" ]
        operation.resultsLimit = cacheSize
// FIX?        operation.configuration.timeoutIntervalForRequest = 30


        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                // TODO: Do something with the record that was received.
                let myRecord = ActivityRecord(fromCKRecord: record)

                DispatchQueue.main.async {
                    print("Adding to cache : \(myRecord)")
                    self.refreshList.append(myRecord)
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

                for record in self.refreshList {
                    print( record.description() )
                }
                
                // copy temporary array to main array and write to local cache
                // only if no unsaved / undeleted items in local cache otherwise cloud view is out of date!
                DispatchQueue.main.async {
                    if !self.dirty() {
                        self.activities = self.refreshList
                        _ = self.write()
                    }
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
                    
                    print("temporary refresh error - set up retry")
                        self.startDeferredRefresh()
                    
                default:
                    print("permanent refresh error - not retrying")
                }
                print( "Fetch failed \(String(describing: error))")
                break
            }

        }
        
        database.add(operation)

    }

    func startDeferredRefresh() {
        let deferredTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(refresh), userInfo: nil, repeats: false)
        deferredTimer.tolerance = 5
    }

    
    
    func CKDelete(recordID: CKRecord.ID) {
        
        print("deleting \(recordID)")
        
        database.delete(withRecordID: recordID) { (ckRecordID, error) in
            
            if let error = error {
                print(error.localizedDescription)
                
                switch error {
                case CKError.unknownItem:
                    print("item being deleted had not been saved")
                    self.remove(recordID: recordID)
                    return
                default:
                    return
                }
                
            }
            
            guard let id = ckRecordID else {
                return
            }
            
            print("deleted and removed \(id)")
            self.remove(recordID: recordID)
            
        }
    }

    func CKSave(activityRecord: ActivityRecord) {

        let CKRecord = activityRecord.asCKRecord()
        print("saving \(activityRecord.recordID!)")

        database.save(CKRecord) { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    switch error {
                    case CKError.accountTemporarilyUnavailable,
                        CKError.networkFailure,
                        CKError.networkUnavailable,
                        CKError.serviceUnavailable,
                        CKError.zoneBusy:
                        
                        print("temporary error")
                    
                    case CKError.serverRecordChanged:
                        // Record alreday exists- shouldn't happen, but!
                        print("record already exists!")
                        activityRecord.deleteTrackRecord()
                        activityRecord.toSave = false
                        
                        _ = self.write()
                        
                    default:
                        print("permanent error")

                    }
                    
                    print("\(error)")

                } else {
                    print("Saved")

                    activityRecord.deleteTrackRecord()
                    activityRecord.toSave = false
                    
                    _ = self.write()
                }
            }
        }
        
    }
 
    @objc func synch() {
        
        if !dirty() { return }
        
        if toBeDeleted().count > 0 {
            CKDelete(recordID: toBeDeleted()[0].recordID)
            return
        }
        
        if toBeSaved().count > 0 {
            CKSave(activityRecord: toBeSaved()[0])
        }
        
        
        
    }
}

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


// MARK: - ActivityDataManager

class ActivityDataManager: NSObject, ObservableObject {
    
    var settingsManager: SettingsManager!
    @Published var recordSet: [ActivityRecord] = []

    var liveActivityRecord: ActivityRecord?

    // Dummy activity record used for previews
    var dummyActivityRecord: ActivityRecord
    
    var dataCache: DataCache

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        dummyActivityRecord = ActivityRecord(settingsManager: settingsManager)
        dataCache = DataCache()

        super.init()

        dataCache.setActivityDataManager(activityDataManager: self)
        
        updateUI()
        
    }
    
    func updateUI() {
        recordSet = dataCache.cache()
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
    

    func saveActivityRecord() {

        if liveActivityRecord != nil {
            liveActivityRecord!.save(dataCache: dataCache)
            updateUI()
        }
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

    
    func delete(recordID: CKRecord.ID) {
        
        dataCache.delete(recordID: recordID)
        
        updateUI()
        
    }

}
