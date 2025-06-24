//
//  CKProfileQuery.swift
//  PulseWorkout
//
//  Created by Robin Murray on 10/04/2025.
//

import Foundation
import Foundation
import CloudKit
import os


class CKProfileQueryOperation: CloudKitOperation {
 
    var blockCompletionFunction: ([CKRecord]) -> Void
    
    init(blockCompletionFunction : @escaping ([CKRecord]) -> Void) {
        
        self.blockCompletionFunction = blockCompletionFunction
        
    }
    
    /// Query definition for fetching Activity Profilesfrom CloudKit
    func profileQueryOperation() -> CKQueryOperation {
        let pred = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "lastUsed", ascending: false)
        
        let query = CKQuery(recordType: "ActivityProfile", predicate: pred)
        query.sortDescriptors = [sort]

        let operation = CKQueryOperation(query: query)

        operation.desiredKeys = ["name", "workoutTypeId", "workoutLocationId",
                                 "hiLimitAlarmActive", "hiLimitAlarm", "loLimitAlarmActive",
                                 "loLimitAlarm", "playSound", "playHaptic",
                                 "constantRepeat", "lockScreen", "lastUsed",
                                 "autoPause", "stravaSaveAll"]
        
        return operation

    }
    
    func execute() {
        
        CKFetchRecordBlockOperation(query: profileQueryOperation(),
                                    blockCompletionFunction: self.blockCompletionFunction).execute()
        
    }
}
