//
//  UpdateActivity.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 21/03/2025.
//

import Foundation
import SwiftyJSON
import StravaSwift


/// Update a strava activity - allows name, description, type to be changed
class StravaUpdateActivity: StravaOperation {

    var activityRecord: ActivityRecord
    var completionHandler: (StravaActivity) -> Void
    var failureCompletionHandler: () -> Void
    var stravaActivityRecord: StravaActivity?

    
    init(activityRecord: ActivityRecord,
         completionHandler: @escaping (StravaActivity) -> Void,
         failureCompletionHandler: @escaping () -> Void = { },
         forceReauth: Bool = false,
         forceRefresh: Bool = false) {
        
        self.activityRecord = activityRecord
        self.completionHandler = completionHandler
        self.failureCompletionHandler = failureCompletionHandler
        
        var json = JSON()

        if let id = activityRecord.stravaId {
            json.dictionaryObject = [
                "id": id,
                "description": activityRecord.activityDescription,
                "name": activityRecord.name,
                "sport_type": activityRecord.stravaType
            ]
            
            self.stravaActivityRecord = StravaActivity(json)
        }

        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)


    }
    
    
    /// If tcx asset alreday loaded use it, else fetch from cloudkit and call upload on completion
    func execute() {
        
        guard let updatableActivity = stravaActivityRecord else {
            self.logger.error("Error : Activity Record is not saved to strava, so cannot be updated")
            return
        }
        if validToken(execFunction: self.execute, failureCompletionHandler: failureCompletionHandler) {

            StravaClient.sharedInstance.request(Router.updateActivity(activity: updatableActivity), result: { [weak self] (activity: StravaActivity?) in

                guard let self = self else { return }
                self.stravaBusyStatus(false)
                self.logger.info("Update completed :: \(activity?.name ?? "NONE")")
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

}
