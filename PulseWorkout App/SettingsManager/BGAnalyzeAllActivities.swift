//
//  BGAnalyzeAllActivities.swift
//  PulseWorkout
//
//  Created by Robin Murray on 08/10/2026.
//

import Foundation
import BackgroundTasks

/// Extension containing all functionality for background processing to re-analyze all activities
/// Only built with iOS
extension SettingsManager {
    
    
    func analyzeAllActivities(completion: @escaping (Bool) -> Void = {_ in}, task: BGTask? = nil) {
    
        var progress: Progress?
        var wasExpired: Bool = false
        var cloudKitOperation: CKProcessAllActivityRecords?
        
        let taskCompletionFunction: () -> Void = {
            DispatchQueue.main.async {
                self.analysisInProgress = false
            }
            if wasExpired {
                completion(false)
            } else {
                completion(true)

            }
        }
        
        
        logger.info("Running activity re-analysis")

        if let task = task as? BGContinuedProcessingTask {
            // Check the expiration handler to confirm job completion.
            task.expirationHandler = {
                self.logger.info("Task expired")
                wasExpired = true
                
                // Cancel the cloudkit operation if the task was expired
                if let operation = cloudKitOperation {
                    operation.cancel()
                    taskCompletionFunction()
                }
            }
            progress = task.progress
        }
        
        
        // UPdate all records in cloudkit
        cloudKitOperation = CKProcessAllActivityRecords(
            recordProcessFunction: {
                ckRecord, recordProcessCompletionFunction
                in
                
                analyzeActivity(ckRecord: ckRecord,
                                recordProcessCompletionFunction: recordProcessCompletionFunction)
                
                // update the live activity widget
                if let task = task as? BGContinuedProcessingTask {
                    task.updateTitle("Re-analyzing all activities",
                                     subtitle: "Completed \(progress!.completedUnitCount)")
 
                }
            },
            completionFunction: taskCompletionFunction,
            progress: progress)
        
        cloudKitOperation!.execute()

    }
    

    // Submit a background continued processing task to rebuild all statistics
    func submitAnalyzeActivitiesTask() {
        
        if analysisInProgress {
            logger.info("Can't submit request, background processing already active.")
            return
        }
        analysisInProgress = true
        
        let request = BGContinuedProcessingTaskRequest(
            identifier: "MurrayNet.PulseWorkout-Phone-App.activityAnalysis",
            title: "Re-analyzing all activities", subtitle: "Starting...")

        logger.info("Submitting background task request")
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Successfully submitted background task request")

        } catch {
            logger.error("Failed to submit background task: \(error.localizedDescription)")
        }
        
    }

}
