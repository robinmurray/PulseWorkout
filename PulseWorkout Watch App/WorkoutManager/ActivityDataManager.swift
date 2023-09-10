//
//  ActivityDataManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 30/06/2023.
//


import Foundation
import CloudKit



func getCacheDirectory() -> URL? {
//    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//    let paths = FileManager.default.temporaryDirectory
    let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("pulseWorkout")
    do {
        try FileManager.default.createDirectory(at: cachePath, withIntermediateDirectories: true)
    } catch {
        print("error \(error)")
        return nil
    }
//    let documentsDirectory = paths[0]
    return cachePath
}

func getTrackFileURL() -> URL? {
    let fileName = NSUUID().uuidString + ".tcx"
    guard let cachePath = getCacheDirectory() else { return nil }
    return cachePath.appendingPathComponent(fileName)
}

class ActivityRecord: NSObject, Identifiable {
    
    let recordType = "activity"
    var recordID: CKRecord.ID!
    var name: String = "Morning Ride"
    var type: String = "Ride"
    var sportType = "Ride"
    var startDateLocal: Date = Date()
    var elapsedTime: Double = 0
    var activityDescription: String = ""
    var heartRate: Double?
    var distanceMeters: Double = 0
    var cadence: Int?
    var watts: Int?
    var speed: Double?
    var averageHeartRate: Double = 0
    var heartRateRecovery: Double = 0
    var activeEnergy: Double = 0

    var timeOverHiAlarm: Double = 0
    var timeUnderLoAlarm: Double = 0
    
    var tcxAsset: CKAsset?
    var tcxURL: URL?        // Temporary cache URL for tcx file
    
 
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
    
    var trackPoints: [TrackPoint] = []

    var stravaStatus: Bool = false

    
    func saveTrackRecord() -> Bool {
        
        tcxURL = getTrackFileURL()
        
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
        if tcxURL != nil {
            do {
                try FileManager.default.removeItem(at: tcxURL!)
                    print("tcx has been deleted")
                } catch {
                    print(error)
                }
            }
        }

    
    
    func createDummy() {
        name = "Morning Ride"
        type = "Ride"
        sportType = "Ride"
        startDateLocal = Date()
        elapsedTime = 10
        activityDescription = ""
        distanceMeters = 5370

        averageHeartRate = 130
        heartRateRecovery = 0
        activeEnergy = 950

        timeOverHiAlarm = 100
        timeUnderLoAlarm = 200
    }
    
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
    
    func addTrackPoint() {


        trackPoints.append(TrackPoint(time: Date(),
                                      heartRate: heartRate,
                                      distanceMeters: distanceMeters,
                                      cadence: cadence,
                                      speed: speed,
                                      watts: watts
                                     )
                            )
        

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
    
    func saveDummyActivityRecord()  {

        let activityRecord = ActivityRecord()
        activityRecord.createDummy()
        saveActivityRecord(activityRecord: activityRecord)

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
