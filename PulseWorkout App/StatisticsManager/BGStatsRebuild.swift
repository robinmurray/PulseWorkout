//
//  BGStatsRebuild.swift
//  PulseWorkout
//
//  Created by Robin Murray on 26/10/2026.
//

import Foundation
import BackgroundTasks

/// Extension containing all functionality for background processing of full Stats Rebuild
/// Only built with iOS
extension StatisticsManager {
    
    /// Register background task to re-analyze all activities
    func registerBackgroundTasks() {
        
        logger.info("Registering background statistics rebuild task")
        // register background tasks that may be called.
        let BGTaskRegistrationResult =
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "MurrayNet.PulseWorkout-Phone-App.statsRebuild",
                                        using: nil) { task in
            
            self.buildStatisticsTask(completion: task.setTaskCompleted, task: task)
            
        }
        logger.info("BG Processing Task registration status \(BGTaskRegistrationResult)")

    }

    
    

    /// Background task registered to complete full refersh of records from Strava.
    /// Each task run fetches a page and then submits a continuation task to do next page
    /// Ongoing status managed in stravaRefreshParameters
    func buildStatisticsTask(completion: @escaping (Bool) -> Void = {_ in}, task: BGTask? = nil) {
        
        let pageReadFailCompletion: () -> Void = {
 
            DispatchQueue.main.async {
                completion(false)
                
                let retry = self.statisticsRebuildParameters.pageReadFailed()
                
                if retry {
                    self.submitContinuationBuildStatisticsTask()
                }
            }
        }
       
        // Called if page read is successful - submits a
        let pageReadSuccessCompletion: (_ recordCount: Int, _ earliestRecord: Date?) -> Void = { recordCount, earliestRecord in
 
            DispatchQueue.main.async {
                completion(true)
                
                let readNext = self.statisticsRebuildParameters.pageReadSuccess(recordCount: recordCount,
                                                                                earliestRecord: earliestRecord)
                
                if readNext {
                    self.submitContinuationBuildStatisticsTask()
                } else {
                    if self.statisticsRebuildParameters.cancelled {
                        self.logger.info("BG Build Statistics Task cancelled: \(self.statisticsRebuildParameters)")
                    } else {
                        self.logger.info("BG Build Statistics Task fully completed: \(self.statisticsRebuildParameters)")
                    }

                }
            }
        }
    
        statisticsRebuildParameters.read()
        logger.info("Running Build Statistics page task with parameters \(statisticsRebuildParameters)")

        if let task = task as? BGProcessingTask {
            logger.info("Task is BGProcessingTask")
            // Check the expiration handler to confirm job completion.
            task.expirationHandler = {
                self.logger.info("Task expired")
                pageReadFailCompletion()
            }
        }

        
        logger.info("Fetching records for statistics with start Date \(statisticsRebuildParameters.pageStartDate, default: "None")")
        CKActivityQueryOperation(startDate: statisticsRebuildParameters.pageStartDate,
                                 blockCompletionFunction :
                                    {ckRecords in
            self.addActivitiesToStats(ckRecordList: ckRecords)

            let recordCount = ckRecords.count
            let earliestRecord: Date? = ckRecords.map( {ActivityRecord(fromCKRecord:$0, fetchtrackData: false).startDateLocal} ).min()
            
            pageReadSuccessCompletion(recordCount, earliestRecord)
            },
                                 failureCompletionFunction: {
            self.logger.info("BGProcessingTask Stats Page Rebuild Failed")
            pageReadFailCompletion()
        },
                                 resultsLimit: statisticsRebuildParameters.pageSize,
                                 qualityOfService: .userInitiated).execute()
        
    }
    
    
    /// Submit a new full Build Statistics task
    /// Initialises a new set of refresh parameters then submits a page refresh/fetch background task
    func submitBuildStatisticsTask() {
        
        // Clear out the current buckets
        statsBuckets.emptyTempBuckets()
        copyTempStatsToLive()
        _ = statsBuckets.write(copyToCK: true)

        DispatchQueue.main.async {
            if self.statisticsRebuildParameters.isInProgress() {
                self.logger.info("Can't submit request, background processing already active.")
                return
            }

            self.statisticsRebuildParameters.new(pageStartDate: nil,
                                                 earliestFetchDate: nil,
                                                 delay: 0,
                                                 pageSize: 200)
            
            self.statisticsRebuildParameters.submitted()
            
            // Call initial run of task - will run immediately
            self.buildStatisticsTask()
            
        }
    }

    
    /// Submits a continuation Build Statistics page task
    func submitContinuationBuildStatisticsTask() {
        
        DispatchQueue.main.async {
            if !self.statisticsRebuildParameters.isInProgress() {
                self.logger.info("Can't submit continuation request, background processing not active.")
                return
            }
            
            let _ = self.submitBuildStatisticsPageTask(earliestBeginDate: Date.now.addingTimeInterval(self.statisticsRebuildParameters.delay))
        }
    }
    
    
    /// Attempt to submit task to build statistics from a page of activity records using parameters in
    /// statisticsRebuildParameters
    /// return true if successful, false otherwise
    func submitBuildStatisticsPageTask(earliestBeginDate: Date = Date.now) -> Bool {
                
        let request = BGProcessingTaskRequest(
            identifier: "MurrayNet.PulseWorkout-Phone-App.statsRebuild")

        request.earliestBeginDate = earliestBeginDate
        request.requiresExternalPower = false
        request.requiresNetworkConnectivity = true
        
        logger.info("Submitting background statistics build task request")
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Successfully submitted background statistics build task request with parameters \(statisticsRebuildParameters)")
            return true

        } catch {
            logger.error("Failed to submit background statistics build task: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.statisticsRebuildParameters.failed()
            }
            return false
        }
        
    }

}
