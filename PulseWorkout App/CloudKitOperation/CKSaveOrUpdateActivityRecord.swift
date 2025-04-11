//
//  CKSaveOrUpdateActivityRecord.swift
//  PulseWorkout
//
//  Created by Robin Murray on 11/04/2025.
//

import Foundation
import CloudKit


/// If the record has a stravaId and that stravaId already exists then update that record
/// Otherwise create record
class CKSaveOrUpdateActivityRecordOperation: CloudKitOperation {
    
    var activityRecord: ActivityRecord
    var completionFunction: (CKRecord.ID?) -> Void
    var failureCompletionFunction: () -> Void
    var asyncProgressNotifier: AsyncProgress?
    
    init(activityRecord: ActivityRecord,
         completionFunction: @escaping (CKRecord.ID?) -> Void,
         failureCompletionFunction: @escaping () -> Void = { },
         asyncProgressNotifier: AsyncProgress? = nil) {
        
        self.activityRecord = activityRecord
        self.completionFunction = completionFunction
        self.failureCompletionFunction = failureCompletionFunction
        self.asyncProgressNotifier = asyncProgressNotifier
        
        super.init()
    }
    
    func execute() {
        // If no stravaId, then save
        if let stravaId = activityRecord.stravaId {
            // If stravaId exists then query to see if stravaId already on existing record
            // If so, then do an update, if not do a create.
            
            CKQueryForStravaIdOperation(stravaId: stravaId,
                                        completionFunction: self.updateOrSave).execute()

        }
        else {
            // No stravaId so save...
            self.logger.info("No stravaID - saving \(self.activityRecord.recordName)")
            if let notifier = asyncProgressNotifier {
                notifier.majorIncrement(message: "Saving \(self.activityRecord.recordName ?? "")")
            }
            save()
        }

    }
    
    /// Completion function for query to find activity record with given StravaId
    func updateOrSave(ckRecords: [CKRecord]) {
        
        if ckRecords.count == 0 {
            self.logger.info("stravaID NOT found - saving \(self.activityRecord.recordName)")
            if let notifier = asyncProgressNotifier {
                notifier.majorIncrement(message: "Saving \(self.activityRecord.recordName ?? "")")
            }
            save()
        }
        else {
            let fetchedRecordId = ckRecords.first!.recordID
            // set recordID from fetched record, and just update fields that can be changed in Strava
            self.logger.info("stravaID found - updating \(self.activityRecord.recordName)")
            if let notifier = asyncProgressNotifier {
                notifier.majorIncrement(message: "Updating \(self.activityRecord.recordName ?? "")")
            }
            activityRecord.recordID = fetchedRecordId
            CKForceUpdateOperation(ckRecord: activityRecord.asMinimalUpdateCKRecord(),
                                   completionFunction: completionFunction).execute()

        }
    }
    
    /// Save activity Record to CK
    func save() {
        
        CKSaveOperation(recordsToSave: [activityRecord.asCKRecord()],
                        recordSaveSuccessCompletionFunction: completionFunction).execute()

    }
}

