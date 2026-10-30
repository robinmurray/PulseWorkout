//
//  CKFetchRecordBlock.swift
//  PulseWorkout
//
//  Created by Robin Murray on 10/04/2025.
//

import Foundation
import CloudKit
import os


class CKFetchRecordBlockOperation: CloudKitOperation {
   
    var query: CKQueryOperation
    var blockCompletionFunction: ([CKRecord]) -> Void
    var failureCompletionFunction: () -> Void
    var resultsLimit: Int
    var qualityOfService: QualityOfService
    var nextCursor: CKQueryOperation.Cursor?
    
    init(query: CKQueryOperation,
         nextCursor: CKQueryOperation.Cursor? = nil,
         blockCompletionFunction: @escaping ([CKRecord]) -> Void,
         failureCompletionFunction: @escaping () -> Void = {},
         resultsLimit: Int = 50,
         qualityOfService: QualityOfService = DEFAULT_CLOUDKIT_QOS) {
        
        self.query = query
        self.nextCursor = nextCursor
        self.blockCompletionFunction = blockCompletionFunction
        self.failureCompletionFunction = failureCompletionFunction
        self.resultsLimit = resultsLimit
        self.qualityOfService = qualityOfService
        
    }
    
    
    func execute() {
        
        var ckRecordList: [CKRecord] = []
        
        let operation: CKQueryOperation
        
        if let cursor = nextCursor {
            operation = CKQueryOperation(cursor: cursor)
        } else {
            operation = query
        }

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
            
            switch result {
            case .success(let cursor):

                // Store cursor for if caller wants to continue the query
                // Caller can reference nextCursor
                self.nextCursor = cursor
                
                self.logger.info("Fetch completion")
                self.blockCompletionFunction(ckRecordList)
                
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
                self.failureCompletionFunction()
                break
            }

        }
        
        self.logger.info("Executing Fetch Record Block with operation: \(operation)")
        database.add(operation)

    }
    
}
