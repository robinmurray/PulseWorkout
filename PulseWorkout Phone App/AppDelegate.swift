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
import StravaSwift

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "sceneDelegate")
    
    let strava: StravaClient
    
    override init() {
        let config = StravaConfig(
            clientId: 138595,
            clientSecret: "86ff0c43b3bdaddc87264a2b85937237639a1ac9",
            redirectUri: "aleph://localhost",
            scopes: [.activityReadAll, .activityWrite],
            delegate: PersistentTokenDelegate()
        )
        strava = StravaClient.sharedInstance.initWithConfig(config)

        super.init()
    }
    
    
    func sceneWillEnterForeground(_ scene: UIScene) {
      // ...
        logger.info("Scene Delegate : sceneWillEnterForeground")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
      // ...
        logger.info("Scene Delegate : sceneDidBecomeActive")
    }

    func sceneWillResignActive(_ scene: UIScene) {
      // ...
        logger.info("Scene Delegate : sceneWillResignActive")
    }

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {

        logger.info("Scene Delegate : willConnectTo")
        // Determine who sent the URL.
        if let urlContext = connectionOptions.urlContexts.first {


            let sendingAppID = urlContext.options.sourceApplication
            let url = urlContext.url
            logger.info("source application = \(sendingAppID ?? "Unknown")")
            logger.info("url = \(url)")


            // Process the URL similarly to the UIApplicationDelegate example.
        }

    }
    
    func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        logger.info("Scene Delegate : openURLContexts")
        
        if let urlContext = URLContexts.first {

            let sendingAppID = urlContext.options.sourceApplication
            let url = urlContext.url
            logger.info("source application = \(sendingAppID ?? "Unknown")")
            logger.info("url = \(url)")
            
            _ = strava.handleAuthorizationRedirect(url)


            // Process the URL similarly to the UIApplicationDelegate example.
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var notificationManager: CloudKitNotificationManager?
  
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "appDelegate")
    
    let strava: StravaClient
    
    override init() {
        let config = StravaConfig(
            clientId: 138595,
            clientSecret: "86ff0c43b3bdaddc87264a2b85937237639a1ac9",
            redirectUri: "aleph://localhost",
            scopes: [.activityReadAll, .activityWrite]
        )
        strava = StravaClient.sharedInstance.initWithConfig(config)
        
        let token = StravaClient.sharedInstance.token
        print("Strava Token: \(String(describing: token))")

        super.init()
    }
    
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
        
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        logger.info("In handle authorization")
        return strava.handleAuthorizationRedirect(url)
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        logger.info("finished launching!")
      
 //       application.registerForRemoteNotifications()
        UIApplication.shared.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

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
