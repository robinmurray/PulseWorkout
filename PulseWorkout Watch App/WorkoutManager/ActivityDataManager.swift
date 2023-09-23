//
//  ActivityDataManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 30/06/2023.
//


import Foundation
import CloudKit



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


class ActivityRecord: NSObject, Identifiable, Codable {
    
    var name: String = "Morning Ride"
    var type: String = "Ride"
    var sportType = "Ride"
    var startDateLocal: Date = Date()
    var elapsedTime: Double = 0
    var activityDescription: String = ""
    var distanceMeters: Double = 0
    var averageHeartRate: Double = 0
    var heartRateRecovery: Double = 0
    var activeEnergy: Double = 0
    var timeOverHiAlarm: Double = 0
    var timeUnderLoAlarm: Double = 0
    var stravaStatus: Bool = false
    var tcxURL: URL?        // Temporary cache URL for tcx file
    
    // Instantaneous data fields
    var heartRate: Double?
    var cadence: Int?
    var watts: Int?
    var speed: Double?
    var latitude: Double?
    var longitude: Double?

    
    // fields used for storing to Cloudkit only
    let recordType = "activity"
    var recordID: CKRecord.ID!
    var tcxAsset: CKAsset?
    
    let baseFileName = NSUUID().uuidString  // base of file name for tcx and json files
 
    
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
            
            if speed != nil || watts != nil {
                let extNode = trackPointNode.addNode(name: "Extensions")
                let tpxNode = extNode.addNode(name: "TPX", attributes: ["xmlns" : "http://www.garmin.com/xmlschemas/ActivityExtension/v2"])
                if speed != nil {
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
             elapsedTime, activityDescription, distanceMeters,
             averageHeartRate, activeEnergy, timeOverHiAlarm, timeUnderLoAlarm, stravaStatus
    }
    
    /// Get URL for JSON file
    func JSONFileURL() -> URL? {
        guard let cachePath = getCacheDirectory() else { return nil }
        return cachePath.appendingPathComponent(baseFileName + ".json")
    }

    /// Write activity record to JSON file in cache folder
    func writeToJSON() -> Bool {
        
        guard let jURL = JSONFileURL() else { return false }
        
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
    func readFromJSON() -> Bool {
        guard let jURL = JSONFileURL() else { return false }
        
        do {
            let data = try Data(contentsOf: jURL)
            let decoder = JSONDecoder()
            let JSONData = try decoder.decode(ActivityRecord.self, from: data)
            print ("Read JSONData name: \(JSONData.name)")
            print ("Read JSONData type: \(JSONData.type)")
            print ("Read JSONData startDateLocal: \(JSONData.startDateLocal)")
            print ("Read JSONData elapsedTime: \(JSONData.elapsedTime)")
            print ("Read JSONData activityDescription: \(JSONData.activityDescription)")
            return true
        }
        catch {
            print("error:\(error)")
            return false
        }
    }

    
    /// Remove temporary .json file from cache folder
    func deleteJSON() {
        guard let jURL = JSONFileURL() else { return }

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
                                      distanceMeters: distanceMeters,
                                      cadence: cadence,
                                      speed: speed,
                                      watts: watts
                                     )
                            )
    }

    func trackFileURL() -> URL? {
        guard let cachePath = getCacheDirectory() else { return nil }
        return cachePath.appendingPathComponent(baseFileName + ".tcx")
    }

    func saveTrackRecord() -> Bool {
        
        tcxURL = trackFileURL()
        
        if tcxURL == nil { return false }
        
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
        let aveHRNode = lapNode.addNode(name: "AverageHeartRate")
        aveHRNode.addValue(name: "Value", value: String(Int(averageHeartRate)))
        lapNode.addValue(name: "TriggerMethod", value: "Manual")
        let trackNode = lapNode.addNode(name: "Track")
        for trackPoint in trackPoints {
            trackPoint.addXMLtoNode(node: trackNode)
        }
        
        do {
            try tcxXMLDoc.serialize().write(to: tcxURL!, atomically: true, encoding: .utf8)
            
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
        guard let tcxURL = trackFileURL() else { return }

        do {
            try FileManager.default.removeItem(at: tcxURL)
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
        activityRecord["activityDescription"] = activityDescription as CKRecordValue
        activityRecord["distance"] = distanceMeters as CKRecordValue

        activityRecord["averageHeartRate"] = averageHeartRate as CKRecordValue
        activityRecord["heartRateRecovery"] = heartRateRecovery as CKRecordValue
        activityRecord["activeEnergy"] = activeEnergy as CKRecordValue

        activityRecord["timeOverHiAlarm"] = timeOverHiAlarm as CKRecordValue
        activityRecord["timeUnderLoAlarm"] = timeUnderLoAlarm as CKRecordValue
        
        
        if saveTrackRecord() {
            print("creating asset!")
            activityRecord["tcx"] = CKAsset(fileURL: tcxURL!)
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
        activityDescription = activityRecord["activityDescription"] ?? "" as String
        distanceMeters = activityRecord["distance"] ?? 0 as Double

        averageHeartRate = activityRecord["averageHeartRate"] ?? 0 as Double
        heartRateRecovery = activityRecord["heartRateRecovery"] ?? 0 as Double
        activeEnergy = activityRecord["activeEnergy"] ?? 0 as Double
        timeOverHiAlarm = activityRecord["timeOverHiAlarm"] ?? 0 as Double
        timeUnderLoAlarm = activityRecord["timeUnderLoAlarm"] ?? 0 as Double

    }

    
}


// MARK: - ActivityDataManager

class ActivityDataManager: NSObject, ObservableObject {
    
    var container: CKContainer!
    var database: CKDatabase!
    var zoneID: CKRecordZone.ID!
    @Published var isBusy: Bool = false
    @Published var fetched: Bool = false
    @Published var recordSet: [ActivityRecord] = []

    override init() {
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
 
    
    func saveActivityRecord(activityRecord: ActivityRecord) {

        // First store activity record to local cache for if defered cloudkit operation required
        let activitySavedLocally = activityRecord.writeToJSON()
        let result = activityRecord.readFromJSON()
        
        let CKRecord = activityRecord.asCKRecord()

        isBusy = true
        
        database.save(CKRecord) { [self] record, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("\(error)")
                    self.isBusy = false
                } else {
                    print("Saved")

                    self.isBusy = false
                    self.recordSet.insert(activityRecord, at: 0)
                    activityRecord.deleteTrackRecord()
                }
            }
        }

        
    }
    
    
    func fetchAll() {
        query()
    }
    
    func query() {
        
        isBusy = true
        recordSet = []
        
        let pred = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: "activity", predicate: pred)
        query.sortDescriptors = [sort]

        let operation = CKQueryOperation(query: query)
        operation.desiredKeys = nil
        operation.resultsLimit = 50


        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                // TODO: Do something with the record that was received.
                let myRecord = ActivityRecord()
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
 //               print("All Ok \(self.recordSet)")
 //               print("Record Count : \(self.recordSet.count)")
                for record in self.recordSet {
                    print( record.description() )
                }
                break
                    
            case .failure(let error):
                // TODO: An error happened at the operation level, check the error and decide what to do. Retry might be applicable, or tell the user to connect to internet, etc..
                print( "Fetch failed \(String(describing: error))")
                break
            }
            DispatchQueue.main.async {
                self.isBusy = false
            }
            
        }
        
        database.add(operation)

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
