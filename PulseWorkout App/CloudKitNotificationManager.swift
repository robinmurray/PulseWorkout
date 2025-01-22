//
//  CloudKitNotificationManager.swift
//  PulseWorkout
//
//  Created by Robin Murray on 14/01/2025.
//


import Foundation
import CloudKit
import UIKit
#if os(watchOS)
import WatchKit
#endif
import os

class CloudKitNotificationManager: CloudKitManager {
 
#if os(iOS)
typealias BackgroundFetchResult = UIBackgroundFetchResult
#endif
#if os(watchOS)
typealias BackgroundFetchResult = WKBackgroundFetchResult
#endif

    let serverChangeTokenKey = "ckServerChangeToken"
    
    struct NotificationFunctions {
        var recordDeletion: (CKRecord.ID) -> Void
        var recordChange: (CKRecord) -> Void
    }
    
    /// Dictionary of record types which can be notified, with registered notification functions
    private var recordTypeNotification: [String: NotificationFunctions] = [:]
    
    
    override init() {
        super.init()
        
        createSubscription()
    }
    
    
    /// Function to create a query subscription - NOT CURRENTLY USED!!
    func createQuerySubscription() {
        // Only proceed if you need to create the subscription.
        guard !UserDefaults.standard.bool(forKey: "didCreateActivityQuerySubscription")
            else { return }
                        
        // Define a predicate that matches records with a tags field
        // that contains the word 'Swift'.
        let predicate = NSPredicate(value: true)
        // NSPredicate(format: "tags CONTAINS %@", "Swift")
                
        // Create a subscription and scope it to the 'activity' record type.
        // Provide a unique identifier for the subscription and declare the
        // circumstances for invoking it.
        let subscription = CKQuerySubscription(recordType: "Activity",
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
                UserDefaults.standard.setValue(true, forKey: "didCreateActivityQuerySubscription")
                self.logger.info("Query subscription created!")
                break
                
            case .failure(let error):
                self.logger.error( "Query subscription creation failed with error: \(String(describing: error))")
                break
            }
        }
        // Set an appropriate QoS and add the operation to the private
        // database's operation queue to execute it.
        operation.qualityOfService = .utility
        database.add(operation)
    }


    /// Set up database change subscription for acivity records
    func createSubscription() {
        
        // Only proceed if the subscription doesn't already exist.
        guard !UserDefaults.standard.bool(forKey: "didCreateZoneSubscription")
            else { return }
                
        // Create a subscription with an ID that's unique within the scope of
        // the user's private database.
        let subscription = CKDatabaseSubscription(subscriptionID: "zone-changes")


        // Scope the subscription to just the 'activity' record type.
//        subscription.recordType = "Activity"

                
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
                self.logger.info( "Subscription created!")

                UserDefaults.standard.setValue(true, forKey: "didCreateZoneSubscription")
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


    private func writeServerChangeToken(token: CKServerChangeToken) {

        do {
            let changeTokenData = try NSKeyedArchiver.archivedData(withRootObject: token as Any, requiringSecureCoding: true)
            UserDefaults.standard.set(changeTokenData, forKey: serverChangeTokenKey)
        } catch {
            logger.error("Failed to archive change token \(error.localizedDescription)")
        }
        
    }

    private func readServerChangeToken() -> CKServerChangeToken? {
        
        let changeTokenData = UserDefaults.standard.data(forKey: serverChangeTokenKey)
        
        if changeTokenData != nil {
            do {
                let changeToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: changeTokenData!)
                logger.info("last change token retrieved")
                return changeToken
            } catch {
                logger.error("Error unarchiving change token \(error.localizedDescription)")
                return nil
            }
            
        }
        return nil
    }



    public func handleNotification(completionHandler: @escaping (BackgroundFetchResult) -> Void) {

        
        // Create a dictionary that maps a record zone ID to its
        // corresponding zone configuration. The configuration
        // contains the server change token from the most recent
        // fetch of that record zone.
        
        
        // Use the ChangeToken to fetch only whatever changes have occurred since the last
        // time we asked, since intermediate push notifications might have been dropped.
        
        let changeToken: CKServerChangeToken? = readServerChangeToken()

        let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
        config.previousServerChangeToken = changeToken
        let configurations: [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneConfiguration] = [zoneID: config]
        
        logger.log("Handle Notification changeToken \(changeToken)")
        // Create a fetch operation with an array of record zone IDs
        // and the zone configuration mapping dictionary.
        let operation = CKFetchRecordZoneChangesOperation(
            recordZoneIDs: [zoneID], configurationsByRecordZoneID: configurations)
        
        
        // Process each changed record as CloudKit returns it.
        operation.recordWasChangedBlock = { (recordID: CKRecord.ID, result: Result<CKRecord, any Error>) in
            
            switch result {
            case .success(let record):

                if let notificationFunction = self.recordTypeNotification[record.recordType] {
                    notificationFunction.recordChange(record)
                }
                
                break
                
            case .failure(let error):

                self.logger.error("Error \(error.localizedDescription)")
                break

            }
            
        }
        
        operation.recordWithIDWasDeletedBlock = { recordID, recordType in
            
            if let notificationFunction = self.recordTypeNotification[recordType] {
                notificationFunction.recordDeletion(recordID)
            }
            
        }
        
        // Cache the change tokens that CloudKit provides as
        // the operation runs.
        operation.recordZoneChangeTokensUpdatedBlock = { recordZoneID, serverChangeToken, _ in
            
            self.logger.log("zone changed ID = \(recordZoneID)")
            if recordZoneID == self.zoneID {
                self.writeServerChangeToken(token: serverChangeToken!)
            }
            
        }
        
        operation.recordZoneFetchResultBlock = {(recordZoneID: CKRecordZone.ID,
                                                 fetchChangesResult: Result<(serverChangeToken: CKServerChangeToken,
                                                                               clientChangeTokenData: Data?,
                                                                               moreComing: Bool), any Error>) in
            switch fetchChangesResult {
                
            case .failure(let error):
                self.logger.error("Error in recordZoneFetchResultBlock \(error.localizedDescription)")

                completionHandler(BackgroundFetchResult.failed)

                
            case .success(let (serverChangeToken, _, _) ):
                
                if recordZoneID == self.zoneID {
                    self.logger.info("Record Zone Change Completed for zone \(recordZoneID)")

                    self.writeServerChangeToken(token: serverChangeToken)
                }

                completionHandler(BackgroundFetchResult.newData)

                
            }
            
        }
        
        
        // Set an appropriate QoS and add the operation to the shared
        // database's operation queue to execute it.
        operation.qualityOfService = .utility
        database.add(operation)
    }


    func registerNotificationFunctions( recordType: String, recordDeletionFunction: @escaping (CKRecord.ID) -> Void, recordChangeFunction: @escaping (CKRecord) -> Void) {
        
        recordTypeNotification[recordType] = NotificationFunctions(recordDeletion: recordDeletionFunction,
                                                                   recordChange: recordChangeFunction)

    }
    
    

}
