//
//  MigrationManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 18/12/2024.
//

import Foundation
import CloudKit
import os

class MigrationManager: NSObject {
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "migrationManager")
    let containerName: String = "iCloud.MurrayNet.Aleph"
    var container: CKContainer!
    var database: CKDatabase!
    var zoneID: CKRecordZone.ID!
    let zoneName: String = "Aleph_Zone"
    var tempFileList: [CKRecord.ID : String] = [:]
    
    var dataCache: DataCache
    
    init(dataCache: DataCache) {

        self.dataCache = dataCache
        container = CKContainer(identifier: containerName)
//        container = CKContainer(identifier: "iCloud.CloudKitLesson")
        database = container.privateCloudDatabase
        zoneID = CKRecordZone.ID(zoneName: zoneName)
        
    }
    
    func createRecordZone() {

        let zoneCreationOperation = CKModifyRecordZonesOperation(recordZonesToSave: [CKRecordZone(zoneID: zoneID)],
                                                                 recordZoneIDsToDelete: [])
        
//        let zoneCreationOperation = CKModifyRecordZonesOperation(recordZonesToSave: [],
//                                                                 recordZoneIDsToDelete: [zoneID])

        zoneCreationOperation.modifyRecordZonesResultBlock = {  (operationResult : Result<Void, any Error>) in
            
            switch operationResult {
            case .success:
                self.logger.info("Record zone created success")
                self.fetchAllRecordsToMove()

                break
                
            case .failure(let error):
                self.logger.error( "Record zone creation error : \(String(describing: error))")

                break
            }

        }
 
        /*
        let newZone = CKRecordZone(zoneID: zoneID)
        Task {
            do {
                print("new Zone : \(newZone)")
                _ = try await database.modifyRecordZones(saving: [newZone], deleting: [])
            } catch {
                print("Error creating zone")
            }
        }
*/
        
                database.add(zoneCreationOperation)
    }
    
    func fetchAllRecordsToMove() {
        
        dataCache.fetchAllRecordIDs(recordCompletionFunction: fetchRecordToMove)
        
//        fetchRecordToMove(recordID: dataCache.UIRecordSet[0].recordID)
    }
    
    func fetchRecordToMove(recordID: CKRecord.ID) {
        
        dataCache.fetchRecord(recordID: recordID,
                              completionFunction: moveRecord, completionFailureFunction: failedFetch)
    }
    
    func moveRecord(record: ActivityRecord) -> Void {
        logger.info("Fetched record : \(record.name)  ID : \(record.recordID)")
        record.recordID = CKRecord.ID(recordName: record.recordName, zoneID: zoneID)
        let ckRecord = record.asCKRecord()
        if record.saveTrackRecord() {
            tempFileList[record.recordID] = record.tcxFileName!
            saveAndDeleteRecord(recordsToSave: [ckRecord], recordIDsToDelete: [])
        } else {
            logger.error("Failed to save track record")
        }
        
    }
    
    func failedFetch() -> Void {
        logger.info("Fetch Failed")
    }
    
    func saveAndDeleteRecord(recordsToSave: [CKRecord],
                             recordIDsToDelete: [CKRecord.ID]) {

        self.logger.log("Saving records: \(recordsToSave.map( {$0.recordID} ))")
        self.logger.log("Deleting records: \(recordIDsToDelete)")


        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
        modifyRecordsOperation.qualityOfService = .userInitiated
        modifyRecordsOperation.isAtomic = false
        
        // recordFetched is a function that gets called for each record retrieved
        modifyRecordsOperation.perRecordSaveBlock = { (recordID: CKRecord.ID, result: Result<CKRecord, any Error>) in
            switch result {
            case .success(let record):
                // populate displayActivityRecord - NOTE tcx asset was fetched, so will parse entire track record
                
//                guard let savedActivityRecord = self.activities.filter({ $0.recordName == recordID.recordName }).first else {return}
                self.logger.log("Saved \(record)")
                
//                savedActivityRecord.deleteTrackRecord()
                break
                
            case .failure(let error):

                switch error {
                case CKError.accountTemporarilyUnavailable,
                    CKError.networkFailure,
                    CKError.networkUnavailable,
                    CKError.serviceUnavailable,
                    CKError.zoneBusy:
                    
                    self.logger.log("temporary error")
                    
                case CKError.serverRecordChanged:
                    // Record already exists- shouldn't happen, but!
                    self.logger.error("record already exists!")
//                    guard let savedActivityRecord = self.activities.filter({ $0.recordName == recordID.recordName }).first else {return}
//                    savedActivityRecord.deleteTrackRecord()
//                    savedActivityRecord.setToSave(false)
                    
//                    _ = self.write()
                    
                default:
                    self.logger.error("permanent error")
                    
                }
                
                self.logger.error("Save failed with error : \(error.localizedDescription)")
                
                break
            }
            self.deleteTempFile(recordID: recordID)

        }
        
        modifyRecordsOperation.perRecordDeleteBlock = { (recordID: CKRecord.ID, result: Result<Void, any Error>) in
            switch result {
            case .success:
                self.logger.log("deleted and removed \(recordID)")
 //               self.removeFromCache(recordID: recordID)
                
                break
                
            case .failure(let error):
                switch error {
                case CKError.unknownItem:
                    self.logger.debug("item being deleted had not been saved")
//                    self.removeFromCache(recordID: recordID)
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
        
        self.database.add(modifyRecordsOperation)

    }
 
    
    func deleteTempFile(recordID: CKRecord.ID) {
        let fileName = tempFileList[recordID]!
        let tURL = CacheURL(fileName: fileName)
            
        if tURL != nil {
            do {
                try FileManager.default.removeItem(at: tURL!)
                    logger.debug("file has been deleted \(fileName)")
            } catch {
                logger.error("error \(error)")
            }
        }
    }
    

}
