//
//  FetchActivities.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 21/03/2025.
//

import Foundation
import StravaSwift
import os


class StravaFetchActivities: StravaOperation {

    var params: [String:String] = [:]
    var completionHandler: ([StravaActivity]) -> Void
    var failureCompletionHandler: () -> Void
    
    
    init(page: Int = 1,
         perPage: Int = 30,
         before: Date? = nil,
         after: Date? = nil,
         completionHandler: @escaping ([StravaActivity]) -> Void,
         failureCompletionHandler: @escaping () -> Void = { },
         forceReauth: Bool = false,
         forceRefresh: Bool = false) {
        
        params["page"] = String(page)
        params["per_page"] = String(perPage)

        if let beforeDate = before {
            let beforeSecs = Int(beforeDate.timeIntervalSince1970)
            params["before"] = String(beforeSecs)
        }

        if let afterDate = after {
            let afterSecs = Int(afterDate.timeIntervalSince1970)
            params["after"] = String(afterSecs)
        }

        self.completionHandler = completionHandler
        self.failureCompletionHandler = failureCompletionHandler
        
        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)

    }


    
    func execute() {
    
        if validToken(execFunction: self.execute, failureCompletionHandler: failureCompletionHandler) {

            StravaClient.sharedInstance.request(Router.athleteActivities(params: params), result: { [weak self] (activities: [StravaActivity]?) in
                guard let self = self else { return }
                self.stravaBusyStatus(false)

                guard let activities = activities else { return }

                self.completionHandler(activities)

            }, failure: { (error: NSError) in
                self.stravaBusyStatus(false)
                self.logger.error("Error : \(error.localizedDescription) :: \(error)")
                if error.code == 429 {
                    self.logger.error("Strava API limit exceeded")
                }
                
                // Call passed failure handler, if present
                self.failureCompletionHandler()
            })
        }

    }
    
    class func dummyCompletion( fetchedActivities: [StravaActivity]) {
        
        let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                            category: "stravaOperation")
        
        var activities: [StravaActivity] = []
        activities = fetchedActivities
        
        logger.info("Fetched Count = \(activities.count)")
        logger.info("Strava activities : \(activities)")
        
    }
}

