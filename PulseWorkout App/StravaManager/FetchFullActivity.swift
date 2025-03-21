//
//  FetchFullActivity.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 21/03/2025.
//

import Foundation
import StravaSwift
import os



class StravaFetchFullActivity: StravaOperation {

    var stravaActivityId: Int
    var completionHandler: (ActivityRecord) -> Void
    var fetchedStravaActivity: StravaActivity?
    var failureCompletionHandler: () -> Void
    
    
    init(stravaActivityId: Int,
         completionHandler: @escaping (ActivityRecord) -> Void,
         failureCompletionHandler: @escaping () -> Void = { },
         forceReauth: Bool = false,
         forceRefresh: Bool = false) {
        
        self.stravaActivityId = stravaActivityId
        self.completionHandler = completionHandler
        self.failureCompletionHandler = failureCompletionHandler
        
        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)

    }


    
    func execute() {
    
        StravaFetchActivity(stravaActivityId: stravaActivityId,
                            completionHandler: self.onFetchActivity,
                            failureCompletionHandler: self.failureCompletionHandler).execute()

    }
    
    func onFetchActivity(stravaActivity: StravaActivity) {
        
        fetchedStravaActivity = stravaActivity
        
        StravaFetchActivityStreams(stravaActivityId: stravaActivityId,
                                   streams: ["time", "distance", "latlng", "heartrate", "altitude", "cadence", "watts", "velocity_smooth"],
                                   completionHandler: self.onFetchActivityStreams,
                                   failureCompletionHandler: failureCompletionHandler).execute()
        
    }
    
    func onFetchActivityStreams(streams: [StravaSwift.Stream]) {
        
        let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                            category: "stravaOperation")
        
        logger.info("Strava streams : \(streams)")
        
        if let stravaActivity = fetchedStravaActivity {
            let activityRecord = ActivityRecord(fromStravaActivity: stravaActivity)
            
            // Add Streams
            activityRecord.addStreams(streams)
            
            // Call original completion handler
            self.completionHandler(activityRecord)
        }
        
    }
    
    class func dummyCompletion(activityRecord: ActivityRecord) {
        
        let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                            category: "stravaOperation")
    
        logger.info("Activity Record : \(activityRecord)")
        
    }
}




class StravaFetchActivityStreams: StravaOperation {

    var stravaActivityId: Int
    var streams: [String]
    var completionHandler: ([StravaSwift.Stream]) -> Void
    var failureCompletionHandler: () -> Void
    
    
    init(stravaActivityId: Int,
         streams: [String],
         completionHandler: @escaping ([StravaSwift.Stream]) -> Void,
         failureCompletionHandler: @escaping () -> Void = { },
         forceReauth: Bool = false,
         forceRefresh: Bool = false) {
        
        self.stravaActivityId = stravaActivityId
        self.streams = streams
        self.completionHandler = completionHandler
        self.failureCompletionHandler = failureCompletionHandler
        
        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)

    }


    
    func execute() {
    
        if validToken(execFunction: self.execute, failureCompletionHandler: failureCompletionHandler) {

            let streamParam = streams.joined(separator: ",")
            StravaClient.sharedInstance.request(Router.activityStreams(id: stravaActivityId, types: streamParam), result: { [weak self] (streams: [StravaSwift.Stream]?) in
                guard let self = self else { return }
                self.stravaBusyStatus(false)

                guard let streams = streams else {
                    self.logger.info("No streams returned")
                    self.completionHandler([])
                    return
                }
                self.logger.info("Got streams")
                self.completionHandler(streams)

            }, failure: { (error: NSError) in
                self.stravaBusyStatus(false)
                // Note this happens when no streams, so not really an error!
                self.logger.error("Error in streams - none returned : \(error.localizedDescription)")
                self.completionHandler([])
//                self.failureCompletionHandler()
            })
        }

    }
    
    class func dummyCompletion(streams: [StravaSwift.Stream]) {
        
        let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                            category: "stravaOperation")
    
        logger.info("Strava streams : \(streams)")
        
    }
}

