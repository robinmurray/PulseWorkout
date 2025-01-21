//
//  CloudKitManager.swift
//  PulseWorkout
//
//  Created by Robin Murray on 06/01/2025.
//

import Foundation
import CloudKit
import os



class CloudKitManager: NSObject, ObservableObject {

    var containerName: String
    var container: CKContainer
    var database: CKDatabase
    var zoneName: String
    var zoneID: CKRecordZone.ID
    
    // NOTE: These are global to all fetches
    @Published var fetching: Bool = false
    @Published var fetchComplete: Bool = false
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "CloudKitManager")
    
    override init() {
        containerName = "iCloud.MurrayNet.Aleph"
        container = CKContainer(identifier: containerName)
        database = container.privateCloudDatabase
        zoneName = "Aleph_Zone"
        zoneID = CKRecordZone.ID(zoneName: zoneName)
        
    }

    
    private func createCKZoneIfNeeded(zoneID: CKRecordZone.ID) async throws {

        guard !UserDefaults.standard.bool(forKey: "zoneCreated") else {
            return
        }

        logger.log("creating zone")
        let newZone = CKRecordZone(zoneID: zoneID)
        _ = try await database.modifyRecordZones(saving: [newZone], deleting: [])

        UserDefaults.standard.set(true, forKey: "zoneCreated")
    }
 
    
    /// Function to create a new recordID in correct zone, given a record name
    func getCKRecordID(recordID: UUID?) -> CKRecord.ID {
        
        let recordName: String = recordID?.uuidString ?? CKRecord.ID().recordName
        
        return CKRecord.ID(recordName: recordName, zoneID: zoneID)
    }

    /// Function to create a new recordID in correct zone from scratch
    func getCKRecordID() -> CKRecord.ID {
        let recordName = CKRecord.ID().recordName
        return CKRecord.ID(recordName: recordName, zoneID: zoneID)
    }
    
    
    /// Query definition for fetching Activity Profilesfrom CloudKit
    func profileQueryOperation() -> CKQueryOperation {
        let pred = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "lastUsed", ascending: false)
        
        let query = CKQuery(recordType: "Profile", predicate: pred)
        query.sortDescriptors = [sort]

        let operation = CKQueryOperation(query: query)

        operation.desiredKeys = ["name", "workoutTypeId", "workoutLocationId",
                                 "hiLimitAlarmActive", "hiLimitAlarm", "loLimitAlarmActive",
                                 "loLimitAlarm", "playSound", "playHaptic",
                                 "constantRepeat", "lockScreen", "lastUsed",
                                 "autoPause"]
        
        return operation

    }
    
    /// Query definition for fetching Bluetooth devices from CloudKit
    func BTDeviceQueryOperation() -> CKQueryOperation {
        let pred = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "name", ascending: true)
        
        let query = CKQuery(recordType: "BTDevices", predicate: pred)
        query.sortDescriptors = [sort]

        let operation = CKQueryOperation(query: query)

        operation.desiredKeys = ["name", "services", "deviceInfo"]
        
        return operation

    }
    
    /// Query definition for fetching activities from CloudKit
    func activityQuery(startDate: Date?) -> CKQueryOperation {
        
        var pred = NSPredicate(value: true)
        if startDate != nil {
            pred = NSPredicate(format: "startDateLocal < %@", startDate! as CVarArg)
        }
        let sort = NSSortDescriptor(key: "startDateLocal", ascending: false)
        let query = CKQuery(recordType: "activity", predicate: pred)
        query.sortDescriptors = [sort]

        let operation = CKQueryOperation(query: query)

        operation.desiredKeys = ["name", "type", "sportType", "startDateLocal", "elapsedTime", "pausedTime", "movingTime",
                                 "activityDescription", "distance", "totalAscent", "totalDescent",
                                 "averageHeartRate", "averageCadence", "averagePower", "averageSpeed",
                                 "maxHeartRate", "maxCadence", "maxPower", "maxSpeed",
                                 "activeEnergy", "timeOverHiAlarm", "timeUnderLoAlarm", "hiHRLimit", "loHRLimit", "mapSnapshot" ]
        
        
        return operation
        
    }
    
    
    func fetchRecordBlock(query: CKQueryOperation,
                          blockCompletionFunction: @escaping ([CKRecord]) -> Void,
                          resultsLimit: Int = 50,
                          qualityOfService: QualityOfService = .utility) {
        
        var ckRecordList: [CKRecord] = []
        
        if fetching {
            logger.info("Not fetching record block because a fetch is currently in progress")
            return
        }

        
        // NOTE flags are global to all fetchRecordBlock operations - use different instances of CloudKitManager if concurrent fetches
        fetching = true
        fetchComplete = false
        
        let operation = query
        operation.resultsLimit = resultsLimit
        operation.qualityOfService = qualityOfService

        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                ckRecordList.append(record)

                break
                
            case .failure(let error):
                self.logger.error( "Fetch failed \(String(describing: error))")
                
                break
            }
        }
            
        operation.queryResultBlock = { result in

            DispatchQueue.main.async {
                self.fetching = false
            }
            
            switch result {
            case .success:

                if ckRecordList.count < resultsLimit {
                    DispatchQueue.main.async {
                        self.fetchComplete = true
                    }
                }
                
                self.logger.info("Fetch completion")
                blockCompletionFunction(ckRecordList)
                
                break
                    
            case .failure(let error):

                switch error {
                case CKError.accountTemporarilyUnavailable,
                    CKError.networkFailure,
                    CKError.networkUnavailable,
                    CKError.serviceUnavailable,
                    CKError.zoneBusy:
//                    CKError.notAuthenticated: //REMOVE!!
                    
                    self.logger.log("Temporary device fetch error")

                    
                default:
                    self.logger.error("permanent device fetch error")
                }
                self.logger.error( "Fetch failed \(String(describing: error))")
                break
            }

        }
        
        database.add(operation)

    }


    func saveAndDeleteRecord(recordsToSave: [CKRecord],
                             recordIDsToDelete: [CKRecord.ID],
                             recordSaveSuccessCompletionFunction: @escaping (CKRecord.ID) -> Void,
                             recordDeleteSuccessCompletionFunction: @escaping (CKRecord.ID) -> Void) {

        logger.info("Saving records: \(recordsToSave.map( {$0.recordID} ))")
        logger.info("Deleting records: \(recordIDsToDelete)")

        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
        modifyRecordsOperation.qualityOfService = .utility
        modifyRecordsOperation.isAtomic = false
        
        // recordFetched is a function that gets called for each record retrieved
        modifyRecordsOperation.perRecordSaveBlock = { (recordID: CKRecord.ID, result: Result<CKRecord, any Error>) in
            switch result {
            case .success:
                self.logger.info("Saved \(recordID)")
                recordSaveSuccessCompletionFunction(recordID)
                                
                break
                
            case .failure(let error):

                switch error {
                case CKError.accountTemporarilyUnavailable,
                    CKError.networkFailure,
                    CKError.networkUnavailable,
                    CKError.serviceUnavailable,
                    CKError.zoneBusy:
                    
                    self.logger.error("temporary error")
                    
                case CKError.serverRecordChanged:
                    // Record already exists- shouldn't happen, but!
                    self.logger.error("record already exists!")
                    recordSaveSuccessCompletionFunction(recordID)
                    
                default:
                    self.logger.error("permanent error")
                    
                }
                
                self.logger.error("Save failed with error : \(error.localizedDescription)")
                
                break
            }

        }
        
        
        modifyRecordsOperation.perRecordDeleteBlock = { (recordID: CKRecord.ID, result: Result<Void, any Error>) in
            switch result {
            case .success:
                self.logger.info("deleted and removed \(recordID)")
                recordDeleteSuccessCompletionFunction(recordID)
                
                break
                
            case .failure(let error):
                switch error {
                case CKError.unknownItem:
                    self.logger.error("item being deleted had not been saved")
                    recordDeleteSuccessCompletionFunction(recordID)

                    return
                default:
                    self.logger.error("Deletion failed with error : \(error.localizedDescription)")
                    return
                }
            }
        }
           
        
        modifyRecordsOperation.modifyRecordsResultBlock = { (operationResult : Result<Void, any Error>) in
        
            switch operationResult {
            case .success:
                self.logger.info("Record modify completed")

                break
                
            case .failure(let error):
                self.logger.error( "modify failed \(String(describing: error))")

                break
            }

        }
        
        database.add(modifyRecordsOperation)

    }
 
  
   
    func CKForceUpdate(ckRecord: CKRecord, completionFunction: @escaping (CKRecord?) -> Void) {
        
        logger.log("updating \(ckRecord.recordID)")
        
        database.modifyRecords(saving: [ckRecord], deleting: [], savePolicy: .changedKeys) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let records):
                    print("Success Records : \(records)")
 
                    for recordResult in records.saveResults {
    
                        switch recordResult.value {
                        case .success(let record):
                            self.logger.log("Record updated \(record)")
                            completionFunction(record)

                        case .failure(let error):
                            self.logger.error("Single Record update failed with error \(error.localizedDescription)")
                            completionFunction(nil)
                        }

                    }

                case .failure(let error):
                    self.logger.error("Batch Record update failed with error \(error.localizedDescription)")

                    completionFunction(nil)
                }
                

            }
        }
    }
    
    func nilUpdateCompletion(_: CKRecord?) -> Void {
        return
    }
    
    
    
    func fetchRecord(recordID: CKRecord.ID,
                     completionFunction: @escaping (CKRecord) -> (),
                     completionFailureFunction: @escaping () -> ()) {

        self.logger.log("Fetching record: \(recordID) from Cloudkit")
        
        // CKRecordID contains the zone from which the records should be retrieved
        let fetchRecordsOperation = CKFetchRecordsOperation(recordIDs: [recordID])
        fetchRecordsOperation.qualityOfService = .userInitiated
        
        // recordFetched is a function that gets called for each record retrieved
        fetchRecordsOperation.perRecordResultBlock = { (recordID: CKRecord.ID, result: Result<CKRecord, any Error>) in
            switch result {
            case .success(let record):
                self.logger.info( "Fetch succeeded : \(recordID)")
                completionFunction(record)

                break
                
            case .failure(let error):
                self.logger.error( "Fetch failed \(String(describing: error))")
                completionFailureFunction()
                
                break
            }
            

        }
        
        fetchRecordsOperation.fetchRecordsResultBlock = { (operationResult : Result<Void, any Error>) in
        
            switch operationResult {
            case .success:
                self.logger.info("Record fetch completed")
                break
                
            case .failure(let error):
                self.logger.error( "Fetch failed \(String(describing: error))")
                completionFailureFunction()
                break
            }

        }
        
        self.database.add(fetchRecordsOperation)

    }
 
}

