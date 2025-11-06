//
//  CKFetchRecord.swift
//  PulseWorkout
//
//  Created by Robin Murray on 11/04/2025.
//

import Foundation
import CloudKit



class CKFetchRecordOperation: CloudKitOperation {
    
    var recordID: CKRecord.ID
    var completionFunction: (CKRecord) -> ()
    var completionFailureFunction: () -> ()

    
    init(recordID: CKRecord.ID,
         completionFunction: @escaping (CKRecord) -> () = { _ in },
         completionFailureFunction: @escaping () -> () = { }) {
        
        self.recordID = recordID
        self.completionFunction = completionFunction
        self.completionFailureFunction = completionFailureFunction
        
    }

    
    func execute() {
            
        self.logger.log("Fetching record: \(self.recordID) from Cloudkit")
        
        // CKRecordID contains the zone from which the records should be retrieved
        let fetchRecordsOperation = CKFetchRecordsOperation(recordIDs: [recordID])
        fetchRecordsOperation.qualityOfService = .userInitiated
        
        // recordFetched is a function that gets called for each record retrieved
        fetchRecordsOperation.perRecordResultBlock = { (recordID: CKRecord.ID, result: Result<CKRecord, any Error>) in
            switch result {
            case .success(let record):
                self.logger.info( "Fetch succeeded : \(recordID)")
                self.completionFunction(record)

                break
                
            case .failure(let error):
                self.logger.error( "Fetch failed \(String(describing: error))")
                self.completionFailureFunction()
                
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
                self.completionFailureFunction()
                break
            }

        }
        
        self.database.add(fetchRecordsOperation)

    }
 
    
    // Async await version of single record fetch
    func asyncExecute() async throws -> CKRecord {
        
        var ckRecord: CKRecord!
        
        do {
            let matchResults = try await database.records(for: [recordID])
            for matchResult in matchResults {
                switch matchResult.value {
                case .success(let record):
                    self.logger.info( "Fetch succeeded : \(matchResult.key)")
                    ckRecord = record

                case .failure(let error):
                    self.logger.error( "Fetch failed \(String(describing: error))")
                    throw error

                }
            }
        } catch let error {
            throw error
        }
        
        return ckRecord
    }
    
}



