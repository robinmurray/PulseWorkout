//
//  CKBlockSaveAndDelete.swift
//  PulseWorkout
//
//  Created by Robin Murray on 03/10/2025.
//

import Foundation
import CloudKit
import os


/// Save and delete a block of records as a single atomic operation

class CKBlockSaveAndDeleteOperation: CloudKitOperation {
    
    var recordsToSave: [CKRecord]
    var recordSaveSuccessCompletionFunction: (CKRecord.ID) -> Void
    var qualityOfService: QualityOfService = .utility
    var recordIDsToDelete: [CKRecord.ID]
    var recordDeleteSuccessCompletionFunction: (CKRecord.ID) -> Void
    var blockSuccessCompletion: () -> Void
    var blockFailureCompletion: () -> Void
    
    init(recordsToSave: [CKRecord],
         recordIDsToDelete: [CKRecord.ID],
         recordSaveSuccessCompletionFunction: @escaping (CKRecord.ID) -> Void = {recordID in },
         recordDeleteSuccessCompletionFunction: @escaping (CKRecord.ID) -> Void  = {recordID in },
         blockSuccessCompletion: @escaping () -> Void = {},
         blockFailureCompletion: @escaping () -> Void = {},
         qualityOfService: QualityOfService = .utility) {
        
        self.recordsToSave = recordsToSave
        self.recordIDsToDelete = recordIDsToDelete
        self.recordSaveSuccessCompletionFunction = recordSaveSuccessCompletionFunction
        self.recordDeleteSuccessCompletionFunction = recordDeleteSuccessCompletionFunction
        self.blockSuccessCompletion = blockSuccessCompletion
        self.blockFailureCompletion = blockFailureCompletion
        self.qualityOfService = qualityOfService
    }
    
    func execute() {
        
        logger.info("Saving records: \(self.recordsToSave.map( {$0.recordID} ))")
        logger.info("Deleting records: \(self.recordIDsToDelete)")
        
        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
        modifyRecordsOperation.qualityOfService = qualityOfService
        modifyRecordsOperation.isAtomic = true                      // Execute as a single transaction
        modifyRecordsOperation.savePolicy = .changedKeys            // Allow updates
        
        
        modifyRecordsOperation.perRecordSaveBlock = { (recordID: CKRecord.ID, result: Result<CKRecord, any Error>) in
            switch result {
            case .success:
                self.logger.info("Saved \(recordID)")
                self.recordSaveSuccessCompletionFunction(recordID)
                
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
                    self.recordSaveSuccessCompletionFunction(recordID)
                    
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
                self.recordDeleteSuccessCompletionFunction(recordID)
                
                break
                
            case .failure(let error):
                switch error {
                case CKError.unknownItem:
                    self.logger.error("item being deleted had not been saved")
                    self.recordDeleteSuccessCompletionFunction(recordID)
                    
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
                self.logger.info("Block record modify completed")
                self.blockSuccessCompletion()
                break
                
            case .failure(let error):
                self.logger.error( "Block record modify failed \(String(describing: error))")
                self.blockFailureCompletion()
                break
            }
            
        }
        
        database.add(modifyRecordsOperation)
        
        
    }
}
