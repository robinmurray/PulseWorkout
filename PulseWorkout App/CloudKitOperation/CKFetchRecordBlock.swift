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
    var resultsLimit: Int
    var qualityOfService: QualityOfService
    
    init(query: CKQueryOperation,
         blockCompletionFunction: @escaping ([CKRecord]) -> Void,
         resultsLimit: Int = 50,
         qualityOfService: QualityOfService = DEFAULT_CLOUDKIT_QOS) {
        
        self.query = query
        self.blockCompletionFunction = blockCompletionFunction
        self.resultsLimit = resultsLimit
        self.qualityOfService = qualityOfService
        
    }
    
    
    func execute() {
        
        var ckRecordList: [CKRecord] = []
        
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
            
            switch result {
            case .success:

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
                break
            }

        }
        
        database.add(operation)

    }
    
}
