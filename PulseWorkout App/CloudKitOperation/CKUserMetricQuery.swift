//
//  CKUserMetricQuery.swift
//  PulseWorkout
//
//  Created by Robin Murray on 18/04/2025.
//

import Foundation
import CloudKit



class CKUserMetricQueryOperation: CloudKitOperation {
 
    var recordType: String
    var completionFunction: ([CKRecord]) -> Void
    
    
    init(recordType: String, completionFunction : @escaping ([CKRecord]) -> Void) {
        
        self.recordType = recordType
        self.completionFunction = completionFunction

    }
    
    
    /// Query definition for fetching user metrics from CloudKit
    func metricQuery() -> CKQueryOperation {
        
        let pred = NSPredicate(value: true)

        let sort = NSSortDescriptor(key: "metricsStartDate", ascending: false)
        let query = CKQuery(recordType: recordType, predicate: pred)
        query.sortDescriptors = [sort]

        let operation = CKQueryOperation(query: query)
       
        return operation
        
    }
    
    func execute() {
        
        CKFetchRecordBlockOperation(query: metricQuery(),
                                    blockCompletionFunction: completionFunction,
                                    qualityOfService: DEFAULT_CLOUDKIT_QOS).execute()
        
    }
}
