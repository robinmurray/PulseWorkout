//
//  ActivityDataManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 30/06/2023.
//

import Foundation
import CloudKit

class ActivityRecord: NSObject, Identifiable {
    
    let recordType = "activity"
    var recordID: CKRecord.ID!
    var name: String = "Morning Ride"
    var type: String = "Ride"
    var sportType = "Ride"
    var startDateLocal: Date = Date()
    var elapsedTime: Double = 0
    var activityDescription: String = ""
    var distance: Double = 0

    var averageHeartRate: Double = 0
    var heartRateRecovery: Double = 0
    var activeEnergy: Double = 0

    var timeOverHiAlarm: Double = 0
    var timeUnderLoAlarm: Double = 0

    var stravaStatus: Bool = false

    func createDummy() {
        name = "Morning Ride"
        type = "Ride"
        sportType = "Ride"
        startDateLocal = Date()
        elapsedTime = 10
        activityDescription = ""
        distance = 5370

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
        activityRecord["distance"] = distance as CKRecordValue

        activityRecord["averageHeartRate"] = averageHeartRate as CKRecordValue
        activityRecord["heartRateRecovery"] = heartRateRecovery as CKRecordValue
        activityRecord["activeEnergy"] = activeEnergy as CKRecordValue

        activityRecord["timeOverHiAlarm"] = timeOverHiAlarm as CKRecordValue
        activityRecord["timeUnderLoAlarm"] = timeUnderLoAlarm as CKRecordValue
        
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
        distance = activityRecord["distance"] ?? 0 as Double

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

        let localStartHour = Int(startDateLocal.formatted(
            Date.FormatStyle()
                .hour(.defaultDigits(amPM: .omitted))
        )) ?? 0
        switch localStartHour {
        case 0 ... 4:
            name = "Night " + sportType

        case 5 ... 11:
            name = "Morning " + sportType

        case 12 ... 16:
            name = "Afternoon " + sportType

        case 17 ... 20:
            name = "Evening " + sportType
            
        case 21 ... 24:
            name = "Night " + sportType

        default:
            name = "Morning " + sportType
        }

        activityDescription = activityProfile.name
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

        print("Adding CK Record \(CKRecord)")
 //       print("CK Asset \(myCKAsset)")
        
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
