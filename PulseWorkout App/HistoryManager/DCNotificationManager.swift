//
//  DCNotificationManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 20/12/2024.
//

import Foundation
import CloudKit

/// Extension of datacache to manage subscriptions and notifications
extension DataCache {
    
    
    func createQuerySubscription() {
        // Only proceed if you need to create the subscription.
 //       guard !UserDefaults.standard.bool(forKey: "didCreateActivitySubscription")
 //           else { return }
                        
        // Define a predicate that matches records with a tags field
        // that contains the word 'Swift'.
        let predicate = NSPredicate(value: true)
        // NSPredicate(format: "tags CONTAINS %@", "Swift")
                
        // Create a subscription and scope it to the 'activity' record type.
        // Provide a unique identifier for the subscription and declare the
        // circumstances for invoking it.
        let subscription = CKQuerySubscription(recordType: "activity",
                                               predicate: predicate,
                                               subscriptionID: "activity-changes",
                                               options: [.firesOnRecordCreation,
                                                .firesOnRecordUpdate,
                                                .firesOnRecordDeletion])


        // Further specialize the subscription to only evaluate
        // records in a specific record zone.
        subscription.zoneID = zoneID
                
        // Configure the notification so that the system delivers it silently
        // and, therefore, doesn't require permission from the user.
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
                
        // Save the subscription to the server.
        let operation = CKModifySubscriptionsOperation(
            subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)

        operation.modifySubscriptionsResultBlock = { result in
            switch result {
            case .success:
                // Record that the system successfully creates the subscription
                // to prevent unnecessary trips to the server in later launches.
                UserDefaults.standard.setValue(true, forKey: "didCreateActivitySubscription")
                self.logger.info("Subscription created!")
                break
                
            case .failure(let error):
                self.logger.error( "Subscription creation failed with error: \(String(describing: error))")
                break
            }
        }
        // Set an appropriate QoS and add the operation to the private
        // database's operation queue to execute it.
        operation.qualityOfService = .utility
        database.add(operation)
    }
    
    
    func createSubscription() {
        
        // Only proceed if the subscription doesn't already exist.
        guard !UserDefaults.standard.bool(forKey: "didCreateActivitySubscription")
            else { return }
                
        // Create a subscription with an ID that's unique within the scope of
        // the user's private database.
        let subscription = CKDatabaseSubscription(subscriptionID: "activity-changes")


        // Scope the subscription to just the 'activity' record type.
        subscription.recordType = "activity"

                
        // Configure the notification so that the system delivers it silently
        // and, therefore, doesn't require permission from the user.
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
                
        // Create an operation that saves the subscription to the server.
        let operation = CKModifySubscriptionsOperation(
            subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)

        operation.modifySubscriptionsResultBlock = { result in
            switch result {
            case .success:
                // Record that the system successfully creates the subscription
                // to prevent unnecessary trips to the server in later launches.
                UserDefaults.standard.setValue(true, forKey: "didCreateActivitySubscription")
                break
                
            case .failure(let error):
                self.logger.error( "Subscription creation failed with error: \(String(describing: error))")
                break
            }
        }
                
        // Set an appropriate QoS and add the operation to the private
        // database's operation queue to execute it.
        operation.qualityOfService = .utility
        database.add(operation)
        
    }


    
    public func handleNotification() {
        // Create a dictionary that maps a record zone ID to its
        // corresponding zone configuration. The configuration
        // contains the server change token from the most recent
        // fetch of that record zone.
        
        
        // Use the ChangeToken to fetch only whatever changes have occurred since the last
        // time we asked, since intermediate push notifications might have been dropped.
        let serverChangeTokenKey = "ckServerChangeToken"
        var changeToken: CKServerChangeToken? = nil
        let changeTokenData = UserDefaults.standard.data(forKey: serverChangeTokenKey)
        
        if changeTokenData != nil {
            changeToken = NSKeyedUnarchiver.unarchiveObject(with: changeTokenData!) as! CKServerChangeToken?
        }
        
        let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        config.previousServerChangeToken = changeToken
        var configurations: [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneConfiguration] = [zoneID: config]
        
        logger.log("Handle Notification changeToken \(changeToken)")
        // Create a fetch operation with an array of record zone IDs
        // and the zone configuration mapping dictionary.
        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: [zoneID], configurationsByRecordZoneID: configurations)
        
        
        // Process each changed record as CloudKit returns it.
        operation.recordWasChangedBlock = { (recordID: CKRecord.ID, result: Result<CKRecord, any Error>) in
            
            switch result {
            case .success(let record):

                self.processRecordChangeNofification(record: record)
                
                break
                
            case .failure(let error):

                self.logger.error("Error \(error.localizedDescription)")
                break

            }
            
        }
        
        operation.recordWithIDWasDeletedBlock = { recordID, recordType in
            
            if recordType == "activity" {
                self.processRecordDeletedNotification(recordID: recordID)
            }
            
        }
        
        // Cache the change tokens that CloudKit provides as
        // the operation runs.
        operation.recordZoneChangeTokensUpdatedBlock = { recordZoneID, token, _ in
            
            self.logger.log("zone changed ID = \(recordZoneID)")
            if recordZoneID == self.zoneID {
                let changeTokenData = NSKeyedArchiver.archivedData(withRootObject: token)
                UserDefaults.standard.set(changeTokenData, forKey: serverChangeTokenKey)
            }
            
        }
        
        
        // If the fetch for the current record zone completes
        // successfully, cache the final change token.
        operation.recordZoneFetchCompletionBlock = { recordZoneID, token, _, _, error in
            if let error = error {
                self.logger.error("Error in recordZoneFetchCompletionBlock \(error.localizedDescription)")
            } else {
                if recordZoneID == self.zoneID {
                    let changeTokenData = NSKeyedArchiver.archivedData(withRootObject: token)
                    UserDefaults.standard.set(changeTokenData, forKey: serverChangeTokenKey)
                }
            }
        }
        
        
        // Set an appropriate QoS and add the operation to the shared
        // database's operation queue to execute it.
        operation.qualityOfService = .utility
        database.add(operation)
    }
    
    
    private func processRecordDeletedNotification(recordID: CKRecord.ID) {
        
        logger.log("Processing record deletion: \(recordID)")
        removeFromCache(recordID: recordID)
        removeFromUI(recordID: recordID)
        
    }

    
    private func processRecordChangeNofification(record: CKRecord) {
        logger.log("Processing record change: \(record)")
    }
    

    
    
}
