//
//  BGStravaRefresh.swift
//  PulseWorkout
//
//  Created by Robin Murray on 08/10/2026.
//

import Foundation
import BackgroundTasks

/// Extension containing all functionality for background processing of full Strava Refresh
/// Only built with iOS
extension SettingsManager {
    
    /// Register background task to re-analyze all activities
    func registerBackgroundTasks() {
        
        logger.info("Registering BG Processing Task for Full Strava Refresh")
        // register background tasks that may be called.
        let BGTaskRegistrationResult =
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "MurrayNet.PulseWorkout-Phone-App.fullStravaRefresh",
                                        using: nil) { task in
            
            self.fullStravaRefreshTask(completion: task.setTaskCompleted, task: task)
            
        }
        logger.info("BG Processing Task registration status \(BGTaskRegistrationResult)")
    }

    
    

    /// Background task registered to complete full refersh of records from Strava.
    /// Each task run fetches a page and then submits a continuation task to do next page
    /// Ongoing status managed in stravaRefreshParameters
    func fullStravaRefreshTask(completion: @escaping (Bool) -> Void = {_ in}, task: BGTask? = nil) {
        
        let pageReadFailCompletion: () -> Void = {
 
            DispatchQueue.main.async {
                completion(false)
                
                let retry = self.stravaRefreshParameters.pageReadFailed()
                
                if retry {
                    self.submitContinuationStravaRefreshTask()
                }
            }
        }
       
        // Called if page read is successful - submits a
        let pageReadSuccessCompletion: () -> Void = {
 
            DispatchQueue.main.async {
                completion(true)
                
                let readNext = self.stravaRefreshParameters.pageReadSuccess()
                
                if readNext {
                    self.submitContinuationStravaRefreshTask()
                }
            }
        }
    
        stravaRefreshParameters.read()
        logger.info("Running Strava Page Refresh task with parameters \(stravaRefreshParameters)")

        if let task = task as? BGProcessingTask {
            logger.info("Task is BGProcessingTask")
            // Check the expiration handler to confirm job completion.
            task.expirationHandler = {
                self.logger.info("Task expired")
                pageReadFailCompletion()
            }
        }


        let before = stravaRefreshParameters.pageStartDate ?? Date.now
        let after = stravaRefreshParameters.pageEndDate ?? Date.now
        StravaFetchLatestActivities(
            after: after,
            before: before,
            completionHandler: {
                self.logger.info("BGProcessingTask Full Strava Refresh page completed: \(after) to \(before)")
                pageReadSuccessCompletion()
            },
            failureCompletionHandler: {
                self.logger.info("BGProcessingTask Full Strava Refresh Failed")
                pageReadFailCompletion()
            },
            dataCache: DataCache.shared).execute()
        
    }

    
    
    /// Function to cancel background task
    /// Cancel the task on the task scheduler and set cancelled parameters in parameter set.
    func cancelFullStravaRefreshTask() {
        
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "MurrayNet.PulseWorkout-Phone-App.fullStravaRefresh")
        
        stravaRefreshParameters.cancelRequest()
        
    }
    
    
    /// Submit a new Strava refresh task
    /// Initialises a new set of refresh parameters then submits a page refresh/fetch background task
    func submitNewFullStravaRefreshTask(from: Date) {
        
        DispatchQueue.main.async {
            if self.stravaRefreshParameters.isInProgress() {
                self.logger.info("Can't submit request, background processing already active.")
                return
            }

            self.stravaRefreshParameters.new(earliestFetchDate: from)
            
            if self.submitStravaPageRefreshTask() {
                self.stravaRefreshParameters.submitted()
            }
        }
    }

    
    /// Submits a continuation Strava page refresh task
    func submitContinuationStravaRefreshTask() {
        
        DispatchQueue.main.async {
            if !self.stravaRefreshParameters.isInProgress() {
                self.logger.info("Can't submit continuation request, background processing not active.")
                return
            }
            
            let _ = self.submitStravaPageRefreshTask(earliestBeginDate: Date.now.addingTimeInterval(self.stravaRefreshParameters.delay))
        }
    }
    
    
    /// Attempt to submit task to refresh a page from Strava using parameters in
    /// stravaRefreshParameters
    /// return true if successful, false otherwise
    func submitStravaPageRefreshTask(earliestBeginDate: Date = Date.now) -> Bool {
                
        let request = BGProcessingTaskRequest(
            identifier: "MurrayNet.PulseWorkout-Phone-App.fullStravaRefresh")

        request.earliestBeginDate = earliestBeginDate
        request.requiresExternalPower = false
        request.requiresNetworkConnectivity = true
        
        logger.info("Submitting background full Strava refresh task request")
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Successfully submitted background full Strava refresh task request with parameters \(stravaRefreshParameters)")
            return true

        } catch {
            logger.error("Failed to submit background full Strava Refresh task: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.stravaRefreshParameters.failed()
            }
            return false
        }
        
    }

}
