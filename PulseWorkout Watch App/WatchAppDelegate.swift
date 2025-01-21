//
//  WatchAppDelegate.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 22/12/2024.
//

import Foundation
import WatchKit
import os
import CloudKit

class WatchAppDelegate: NSObject, WKApplicationDelegate {

    var notificationManager: CloudKitNotificationManager?
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "appDelegate")

    func applicationDidFinishLaunching() {
        WKExtension.shared().registerForRemoteNotifications()
    }
    
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
     
        // hexadecimal version of device token for push notification console
        logger.info("deviceToken: \(deviceToken.map { String(format: "%02x", $0) }.joined().uppercased())")
        
        logger.info("Did register for notification!")
    }
    
    func didFailToRegisterForRemoteNotificationsWithError(_ error: any Error) {
        
        logger.error("Failed to register for notification with error \(error)")
        
    }

    func didReceiveRemoteNotification(_ userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (WKBackgroundFetchResult) -> Void) {

        // Whenever there's a remote notification, this gets called
        
        logger.info("Got notification!")
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        let subscriptionOwnerUserRecordID = notification?.subscriptionOwnerUserRecordID
        logger.info("notification : \(String(describing: notification))")
        logger.info("subscriptionOwnerUserRecordID \(String(describing: subscriptionOwnerUserRecordID))")
        
        let notificationType = notification?.notificationType
        logger.info("notification Type : \(String(describing: notificationType))")
        
        // notification type should be query type
        if (notification?.subscriptionID == "zone-changes") {

            notificationManager!.handleNotification(completionHandler: completionHandler)

        }
    }

}
