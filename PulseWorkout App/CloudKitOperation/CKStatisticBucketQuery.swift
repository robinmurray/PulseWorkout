//
//  CKStatisticBucketQuery.swift
//  PulseWorkout
//
//  Created by Robin Murray on 21/10/2025.
//

import Foundation
import CloudKit
import os


class CKStatisticBucketQueryOperation: CloudKitOperation {
 
    var blockCompletionFunction: ([CKRecord]) -> Void
    
    init(blockCompletionFunction : @escaping ([CKRecord]) -> Void) {
        
        self.blockCompletionFunction = blockCompletionFunction
        
    }
    
    /// Query definition for fetching Activity Profilesfrom CloudKit
    func bucketQueryOperation() -> CKQueryOperation {
        let pred = NSPredicate(value: true)
        let sort1 = NSSortDescriptor(key: "bucketType", ascending: true)
        let sort2 = NSSortDescriptor(key: "startDate", ascending: false)

        let query = CKQuery(recordType: "StatisticBucket", predicate: pred)
        query.sortDescriptors = [sort1, sort2]

        let operation = CKQueryOperation(query: query)

        
        return operation

    }
    
    func execute() {
        
        CKFetchRecordBlockOperation(query: bucketQueryOperation(),
                                    blockCompletionFunction: self.blockCompletionFunction).execute()
        
    }
}
