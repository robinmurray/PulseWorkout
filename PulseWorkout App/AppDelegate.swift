//
//  AppDelegate.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 09/12/2024.
//

import Foundation
import UIKit
import CloudKit
import os

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var dataCache: DataCache?
  
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "appDelegate")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        logger.info("finished launching!")
      
 //       application.registerForRemoteNotifications()
        UIApplication.shared.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken
        
        // hexadecimal version of device token for push notification console
        logger.info("deviceToken: \(deviceToken.map { String(format: "%02x", $0) }.joined().uppercased())")
        
        logger.info("Did register for notification!")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        
        logger.error("Failed to register for notificatoni with error \(error)")
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Whenever there's a remote notification, this gets called
        
        logger.info("Got notification!")
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        let subscriptionOwnerUserRecordID = notification?.subscriptionOwnerUserRecordID
        print("notification : \(String(describing: notification))")
        print("subscriptionOwnerUserRecordID \(String(describing: subscriptionOwnerUserRecordID))")
        
        let notificationType = notification?.notificationType
        print("notification Type : \(String(describing: notificationType))")
        
        // notification type should be query type
        
        if (notification?.subscriptionID == "activity-changes") {
            // fetchChanges is a local function used for fetching the modified records from CloudKit

            fetchChanges() { (records) in
                
 //               if records.count > 0 {
                logger.info("new data completion!")
                    completionHandler(UIBackgroundFetchResult.newData)
                    return

//                }
//                print("no data completion!")
//                completionHandler(UIBackgroundFetchResult.noData)
            }
            
        }
        
    }
    
    func fetchChanges(completion: (_ records: [CKRecord])-> Void ) {

        logger.info("fetching changes")
//        dataCache!.handleNotification()
        
        // FIX - this isn't in right place! - needs to be passed to handle notification
        completion([])
        

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.dataCache!.refreshUI()
        }

        
    }
    
}
