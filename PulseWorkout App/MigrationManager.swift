//
//  MigrationManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 18/12/2024.
//

import Foundation
import CloudKit
import os

class MigrationManager: CloudKitManager {
    
    let localLogger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "migrationManager")

    var tempFileList: [CKRecord.ID : String] = [:]

    

    
    func createRecordZone() {

        let zoneCreationOperation = CKModifyRecordZonesOperation(recordZonesToSave: [CKRecordZone(zoneID: zoneID)],
                                                                 recordZoneIDsToDelete: [])
        
//        let zoneCreationOperation = CKModifyRecordZonesOperation(recordZonesToSave: [],
//                                                                 recordZoneIDsToDelete: [zoneID])

        zoneCreationOperation.modifyRecordZonesResultBlock = {  (operationResult : Result<Void, any Error>) in
            
            switch operationResult {
            case .success:
                self.localLogger.info("Record zone created success")
                self.fetchAllRecordsToMove()

                break
                
            case .failure(let error):
                self.localLogger.error( "Record zone creation error : \(String(describing: error))")

                break
            }

        }
 

        
                database.add(zoneCreationOperation)
    }
    
    func fetchAllRecordsToMove() {
        
        fetchAllRecordIDs(recordCompletionFunction: fetchRecordToMove)
        
    }
    
    func fetchRecordToMove(recordID: CKRecord.ID) {
        
        fetchRecord(recordID: recordID,
                    completionFunction: moveRecord,
                    completionFailureFunction: failedFetch)
    }
    
    func moveRecord(CKrecord: CKRecord) -> Void {
        let record = ActivityRecord(fromCKRecord: CKrecord, settingsManager: SettingsManager())
        localLogger.info("Fetched record : \(record.name)  ID : \(record.recordID)")
        record.recordID = CKRecord.ID(recordName: record.recordName, zoneID: zoneID)
        let ckRecord = record.asCKRecord()
        if record.saveTrackRecord() {
            tempFileList[record.recordID] = record.tcxFileName!
            saveAndDeleteRecord(recordsToSave: [ckRecord], recordIDsToDelete: [])
        } else {
            localLogger.error("Failed to save track record")
        }
        
    }
    
    func failedFetch() -> Void {
        localLogger.info("Fetch Failed")
    }
    
    func saveAndDeleteRecord(recordsToSave: [CKRecord],
                             recordIDsToDelete: [CKRecord.ID]) {

        self.localLogger.log("Saving records: \(recordsToSave.map( {$0.recordID} ))")
        self.localLogger.log("Deleting records: \(recordIDsToDelete)")


        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
        modifyRecordsOperation.qualityOfService = .userInitiated
        modifyRecordsOperation.isAtomic = false
        
        // recordFetched is a function that gets called for each record retrieved
        modifyRecordsOperation.perRecordSaveBlock = { (recordID: CKRecord.ID, result: Result<CKRecord, any Error>) in
            switch result {
            case .success(let record):
                // populate displayActivityRecord - NOTE tcx asset was fetched, so will parse entire track record
                
//                guard let savedActivityRecord = self.activities.filter({ $0.recordName == recordID.recordName }).first else {return}
                self.localLogger.log("Saved \(record)")
                
//                savedActivityRecord.deleteTrackRecord()
                break
                
            case .failure(let error):

                switch error {
                case CKError.accountTemporarilyUnavailable,
                    CKError.networkFailure,
                    CKError.networkUnavailable,
                    CKError.serviceUnavailable,
                    CKError.zoneBusy:
                    
                    self.localLogger.log("temporary error")
                    
                case CKError.serverRecordChanged:
                    // Record already exists- shouldn't happen, but!
                    self.localLogger.error("record already exists!")
//                    guard let savedActivityRecord = self.activities.filter({ $0.recordName == recordID.recordName }).first else {return}
//                    savedActivityRecord.deleteTrackRecord()
//                    savedActivityRecord.setToSave(false)
                    
//                    _ = self.write()
                    
                default:
                    self.localLogger.error("permanent error")
                    
                }
                
                self.localLogger.error("Save failed with error : \(error.localizedDescription)")
                
                break
            }
            self.deleteTempFile(recordID: recordID)

        }
        
        modifyRecordsOperation.perRecordDeleteBlock = { (recordID: CKRecord.ID, result: Result<Void, any Error>) in
            switch result {
            case .success:
                self.localLogger.log("deleted and removed \(recordID)")
 //               self.removeFromCache(recordID: recordID)
                
                break
                
            case .failure(let error):
                switch error {
                case CKError.unknownItem:
                    self.localLogger.debug("item being deleted had not been saved")
//                    self.removeFromCache(recordID: recordID)
                    return
                default:
                    self.localLogger.error("Deletion failed with error : \(error.localizedDescription)")
                    return
                }
            }
        }
            
        modifyRecordsOperation.modifyRecordsResultBlock = { (operationResult : Result<Void, any Error>) in
        
            switch operationResult {
            case .success:
                self.localLogger.info("Record modify completed")

                break
                
            case .failure(let error):
                self.localLogger.error( "modify failed \(String(describing: error))")

                break
            }

        }
        
        self.database.add(modifyRecordsOperation)

    }
 
    
    func deleteTempFile(recordID: CKRecord.ID) {
        let fileName = tempFileList[recordID]!
        let tURL = CacheURL(fileName: fileName)
            
        if tURL != nil {
            do {
                try FileManager.default.removeItem(at: tURL!)
                localLogger.debug("file has been deleted \(fileName)")
            } catch {
                localLogger.error("error \(error)")
            }
        }
    }
  
    func fetchAllRecordIDs(recordCompletionFunction: @escaping (CKRecord.ID) -> ()) {
               
        let pred = NSPredicate(value: true)
        var minStartDate: Date? = nil
        var recordCount: Int = 0
        let sort = NSSortDescriptor(key: "startDateLocal", ascending: false)
        let query = CKQuery(recordType: "Activity", predicate: pred)
        query.sortDescriptors = [sort]

        let operation = CKQueryOperation(query: query)

        operation.desiredKeys = ["name", "startDateLocal"]
        operation.qualityOfService = .userInitiated
        operation.resultsLimit = 200


        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                recordCompletionFunction(recordID)
                recordCount += 1
                let startDate: Date = record["startDateLocal"]  ?? Date() as Date
                if minStartDate == nil {
                    minStartDate = startDate
                } else {
                    minStartDate = min(startDate, minStartDate!)
                }
                
                break
                
            case .failure(let error):
                self.localLogger.error( "Fetch failed for recordID \(recordID) : \(String(describing: error))")
                
                break
            }
        }
            
        operation.queryResultBlock = { result in

            switch result {
            case .success:

                self.localLogger.info("Record fetch successfully complete : record count \(recordCount) : min date \(minStartDate!.formatted(Date.ISO8601FormatStyle().dateSeparator(.dash)))")
                
                break
                    
            case .failure(let error):

                switch error {
                case CKError.accountTemporarilyUnavailable,
                    CKError.networkFailure,
                    CKError.networkUnavailable,
                    CKError.serviceUnavailable,
                    CKError.zoneBusy:
                    
                    self.localLogger.log("temporary refresh error")

                    
                default:
                    self.localLogger.error("permanent refresh error - not retrying")
                }
                self.localLogger.error( "Fetch failed \(String(describing: error))")
                break
            }

        }
        
        database.add(operation)

    }


}
