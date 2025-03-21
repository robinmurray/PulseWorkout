//
//  FetchActivity.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 21/03/2025.
//

import Foundation
import StravaSwift
import os




class StravaFetchActivity: StravaOperation {

    var stravaActivityId: Int
    var completionHandler: (StravaActivity) -> Void
    var failureCompletionHandler: () -> Void
    
    
    init(stravaActivityId: Int,
         completionHandler: @escaping (StravaActivity) -> Void,
         failureCompletionHandler: @escaping () -> Void = { },
         forceReauth: Bool = false,
         forceRefresh: Bool = false) {
        
        self.stravaActivityId = stravaActivityId
        self.completionHandler = completionHandler
        self.failureCompletionHandler = failureCompletionHandler
        
        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)

    }


    
    func execute() {
    
        if validToken(execFunction: self.execute, failureCompletionHandler: failureCompletionHandler) {

            StravaClient.sharedInstance.request(Router.activities(id: stravaActivityId, params: nil), result: { [weak self] (activity: StravaActivity?) in
                guard let self = self else { return }
                self.stravaBusyStatus(false)

                guard let activity = activity else { return }

                self.completionHandler(activity)

            }, failure: { (error: NSError) in
                self.stravaBusyStatus(false)
                self.logger.error("Error : \(error.localizedDescription) :: \(error)")
                if error.code == 429 {
                    self.logger.error("Strava API limit exceeded")
                }
                self.failureCompletionHandler()
            })
        }

    }
    
    class func dummyCompletion(fetchedActivity: StravaActivity) {
        
        let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                            category: "stravaOperation")
    
        logger.info("Strava activity : \(fetchedActivity)")
        
    }
}

