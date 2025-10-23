//
//  CKSaveAndDelete.swift
//  PulseWorkout
//
//  Created by Robin Murray on 10/04/2025.
//

import Foundation
import CloudKit
import os


class CKSaveAndDeleteOperation: CloudKitOperation {

    var recordsToSave: [CKRecord]
    var recordSaveSuccessCompletionFunction: (CKRecord.ID) -> Void
    var failureCompletionFunction: () -> Void = { }
    var qualityOfService: QualityOfService = DEFAULT_CLOUDKIT_QOS
    var recordIDsToDelete: [CKRecord.ID]
    var recordDeleteSuccessCompletionFunction: (CKRecord.ID) -> Void
    
    init(recordsToSave: [CKRecord],
         recordIDsToDelete: [CKRecord.ID],
         recordSaveSuccessCompletionFunction: @escaping (CKRecord.ID) -> Void,
         recordDeleteSuccessCompletionFunction: @escaping (CKRecord.ID) -> Void,
         failureCompletionFunction: @escaping () -> Void = {},
         qualityOfService: QualityOfService = DEFAULT_CLOUDKIT_QOS) {
        
        self.recordsToSave = recordsToSave
        self.recordIDsToDelete = recordIDsToDelete
        self.recordSaveSuccessCompletionFunction = recordSaveSuccessCompletionFunction
        self.recordDeleteSuccessCompletionFunction = recordDeleteSuccessCompletionFunction
        self.failureCompletionFunction = failureCompletionFunction
        self.qualityOfService = qualityOfService
    }
    
    func execute() {
        
        logger.info("Saving records: \(self.recordsToSave.map( {$0.recordID} ))")
        logger.info("Deleting records: \(self.recordIDsToDelete)")

        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
        modifyRecordsOperation.qualityOfService = qualityOfService
        modifyRecordsOperation.isAtomic = false
        
        // recordFetched is a function that gets called for each record retrieved
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
                    self.failureCompletionFunction()
                    self.logger.error("temporary error")
                    
                    
                case CKError.serverRecordChanged:
                    // Record already exists- shouldn't happen, but!
                    self.logger.error("record already exists!")
                    self.recordSaveSuccessCompletionFunction(recordID)
                    
                default:
                    self.failureCompletionFunction()
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
                    self.failureCompletionFunction()
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
}


class CKSaveOperation: CloudKitOperation {

    var recordsToSave: [CKRecord]
    var recordSaveSuccessCompletionFunction: (CKRecord.ID) -> Void
    var failureCompletionFunction: () -> Void = { }
    var qualityOfService: QualityOfService = DEFAULT_CLOUDKIT_QOS
    
    init(recordsToSave: [CKRecord],
         recordSaveSuccessCompletionFunction: @escaping (CKRecord.ID) -> Void,
         failureCompletionFunction: @escaping () -> Void = {},
         qualityOfService: QualityOfService = DEFAULT_CLOUDKIT_QOS) {
        
        self.recordsToSave = recordsToSave
        self.recordSaveSuccessCompletionFunction = recordSaveSuccessCompletionFunction
        self.failureCompletionFunction = failureCompletionFunction
        self.qualityOfService = qualityOfService
    }
    
    func execute() {
        
        CKSaveAndDeleteOperation(recordsToSave: recordsToSave,
                                 recordIDsToDelete: [],
                                 recordSaveSuccessCompletionFunction: recordSaveSuccessCompletionFunction,
                                 recordDeleteSuccessCompletionFunction: { _ in },
                                 failureCompletionFunction: failureCompletionFunction,
                                 qualityOfService: qualityOfService).execute()
        
    }
}


class CKDeleteOperation: CloudKitOperation {
    
    var recordIDsToDelete: [CKRecord.ID]
    var recordDeleteSuccessCompletionFunction: (CKRecord.ID) -> Void
    var failureCompletionFunction: () -> Void = { }
    var qualityOfService: QualityOfService = DEFAULT_CLOUDKIT_QOS
   
    init(recordIDsToDelete: [CKRecord.ID],
         recordDeleteSuccessCompletionFunction: @escaping (CKRecord.ID) -> Void,
         failureCompletionFunction: @escaping () -> Void = {},
         qualityOfService: QualityOfService = DEFAULT_CLOUDKIT_QOS) {
        
        self.recordIDsToDelete = recordIDsToDelete
        self.recordDeleteSuccessCompletionFunction = recordDeleteSuccessCompletionFunction
        self.failureCompletionFunction = failureCompletionFunction
        self.qualityOfService = qualityOfService
    }

    
    func execute() {
        
        CKSaveAndDeleteOperation(recordsToSave: [],
                                 recordIDsToDelete: recordIDsToDelete,
                                 recordSaveSuccessCompletionFunction: { _ in },
                                 recordDeleteSuccessCompletionFunction: recordDeleteSuccessCompletionFunction,
                                 failureCompletionFunction: failureCompletionFunction,
                                 qualityOfService: qualityOfService).execute()
        
    }
}


