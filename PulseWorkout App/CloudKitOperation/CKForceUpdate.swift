//
//  CKForceUpdate.swift
//  PulseWorkout
//
//  Created by Robin Murray on 10/04/2025.
//

import Foundation
import CloudKit
import os


class CKForceUpdateOperation: CloudKitOperation {
    
    var ckRecord: CKRecord
    var completionFunction: (CKRecord.ID?) -> Void

    
    init(ckRecord: CKRecord,
         completionFunction: @escaping (CKRecord.ID?) -> Void) {
        
        self.ckRecord = ckRecord
        self.completionFunction = completionFunction

    }
    
    func execute() {
        logger.log("updating \(self.ckRecord.recordID)")
        
        database.modifyRecords(saving: [self.ckRecord], deleting: [], savePolicy: .changedKeys) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let records):

                    for recordResult in records.saveResults {

                        switch recordResult.value {
                        case .success(let record):
                            self.logger.log("Record updated \(record)")
                            self.completionFunction(record.recordID)

                        case .failure(let error):
                            self.logger.error("Single Record update failed with error \(error.localizedDescription)")
                            self.completionFunction(nil)
                        }

                    }

                case .failure(let error):
                    self.logger.error("Batch Record update failed with error \(error.localizedDescription)")

                    self.completionFunction(nil)
                }
                
            }
        }
    }
}


