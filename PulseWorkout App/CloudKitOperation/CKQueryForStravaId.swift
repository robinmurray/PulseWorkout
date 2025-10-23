//
//  CKQueryForStravaId.swift
//  PulseWorkout
//
//  Created by Robin Murray on 10/04/2025.
//

import Foundation
import CloudKit

class CKQueryForStravaIdOperation: CloudKitOperation {
    
    var stravaId: Int
    var completionFunction: ([CKRecord]) -> Void
    var qualityOfService: QualityOfService
    
    init(stravaId: Int, completionFunction: @escaping ([CKRecord]) -> Void, qualityOfService: QualityOfService = DEFAULT_CLOUDKIT_QOS) {

        self.stravaId = stravaId
        self.completionFunction = completionFunction
        self.qualityOfService = qualityOfService
        
        super.init()
    }
    
    func execute() {

        let pred = NSPredicate(format: "stravaId == \(stravaId)")
        let query = CKQuery(recordType: "Activity", predicate: pred)
        let operation = CKQueryOperation(query: query)
        
        // Just fetch minimal details - only really checking for existence
        operation.desiredKeys = ["name", "startDateLocal", "stravaId"]

        CKFetchRecordBlockOperation(query: operation,
                                    blockCompletionFunction: completionFunction,
                                    qualityOfService: qualityOfService).execute()

    }
    
}

