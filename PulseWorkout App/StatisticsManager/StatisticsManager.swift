//
//  StatisticsManager.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 08/06/2025.
//

import Foundation
import os
import CloudKit
import BackgroundTasks




class StatisticsManager: ObservableObject {
    
    ///Access StatisticsManager through StatisticsManager.shared
    public static let shared = StatisticsManager()
    
    /// Array of statistics buckets representing this week by day
    @Published var thisWeekDayBuckets: StatisticsBucketArray
    
    /// Array of statistics buckets representing last week by day
    @Published var lastWeekDayBuckets: StatisticsBucketArray
    
    /// Array of statistics buckets representing the last 12 weeks by week
    @Published var weekBuckets: StatisticsBucketArray
    
    /// Array of statistics buckets representing the last 4 quarters by quarter
    @Published var quarterBuckets: StatisticsBucketArray
    
    /// Array of statistics buckets representing the last 2 years by year
    @Published var yearBuckets: StatisticsBucketArray
    
    /// Flag to show if statistics being rebuilt
    @Published var refreshInProgress: Bool = false
    @Published var refreshCompleteDate: Date? = nil
    
    @Published var stravaSaveInProgress: Bool = false
    @Published var stravaSaveSubmitDate: Date? = nil
    @Published var stravaSaveCompleteDate: Date? = nil
    
    @Published var activityAnalysisInProgress: Bool = false
    @Published var activityAnalysisSubmitDate: Date? = nil
    @Published var activityAnalysisCompleteDate: Date? = nil
    
    @Published var BGTaskTestStatus: String = "None"
    
    /// The full set of statistics buckets
    var statsBuckets: StatisticsBucketArray
    
    /// Internal variable to manage completion function of statistics refresh operation
    private var onRefreshCompletionFunc: () -> Void = {}
    
    let logger = ComponentLogger("StatisticsManager")
    
    init() {
        self.statsBuckets = StatisticsBucketArray()
        self.thisWeekDayBuckets = statsBuckets.thisWeekDayBuckets()
        self.lastWeekDayBuckets = statsBuckets.lastWeekDayBuckets()
        self.weekBuckets = statsBuckets.weekBuckets()
        self.quarterBuckets = statsBuckets.quarterBuckets()
        self.yearBuckets = statsBuckets.yearBuckets()
        self.refreshCompleteDate = UserDefaults.standard.object(forKey: "statisticsRefreshDate") as? Date ?? nil
        self.stravaSaveSubmitDate = UserDefaults.standard.object(forKey: "stravaSaveSubmitDate") as? Date ?? nil
        self.stravaSaveCompleteDate = UserDefaults.standard.object(forKey: "stravaSaveCompleteDate") as? Date ?? nil

        self.activityAnalysisSubmitDate = UserDefaults.standard.object(forKey: "activityAnalysisSubmitDate") as? Date ?? nil
        self.activityAnalysisCompleteDate = UserDefaults.standard.object(forKey: "activityAnalysisCompleteDate") as? Date ?? nil
    }
    
    
    /// Set all published variables for UI update
    func reset() {
        DispatchQueue.main.async {
            self.thisWeekDayBuckets = self.statsBuckets.thisWeekDayBuckets()
            self.lastWeekDayBuckets = self.statsBuckets.lastWeekDayBuckets()
            self.weekBuckets = self.statsBuckets.weekBuckets()
            self.quarterBuckets = self.statsBuckets.quarterBuckets()
            self.yearBuckets = self.statsBuckets.yearBuckets()
            
        }
    }
    
    
    /// Return this week statistic bucket
    func thisWeek() -> StatisticsBucket {
        return weekBuckets.elements.last!
    }
    
    
    /// Return last week statistic bucket
    func lastWeek() -> StatisticsBucket {
        let weekCount = weekBuckets.elements.count
        let lastWeekIndex = max(weekCount - 2, 0)
        return weekBuckets.elements[lastWeekIndex]
    }
    
    /// Return this year statistic bucket
    func thisYear() -> StatisticsBucket {
        return yearBuckets.elements.last!
    }
    
    /// Return last week statistic bucket
    func lastYear() -> StatisticsBucket {
        return yearBuckets.elements.first!
    }
    
#if os(iOS)
    @available(iOS 26.0, *)
    func registerBackgroundBuild() {
        
        logger.info("Registering background statistics rebuild task")
        // register background tasks that may be called.
        let continuationTaskresult =
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "MurrayNet.PulseWorkout-Phone-App.statsRebuild",
                                        using: nil) { task in
            
            self.buildStatisticsTask(completion: task.setTaskCompleted, task: task)
            
        }
        logger.info("BG Continuation Task registration status \(continuationTaskresult)")
        
        
        logger.info("Registering App Refresh Task for Strava Save")
        // register background tasks that may be called.
        let registrationResult =
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "MurrayNet.PulseWorkout-Phone-App.stravaSave",
                                        using: nil) { task in
            
            self.stravaSaveTask(completion: task.setTaskCompleted, task: task)
            
        }
        logger.info("App Refresh Task registration status \(registrationResult)")
        
        logger.info("Registering BG Processing Task for Activity Analysis")
        // register background tasks that may be called.
        let BGTaskRegistrationResult =
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "MurrayNet.PulseWorkout-Phone-App.activityAnalysis",
                                        using: nil) { task in
            
            self.activityAnalysisTask(completion: task.setTaskCompleted, task: task)
            
        }
        logger.info("BG Processing Task registration status \(BGTaskRegistrationResult)")
    }
    
    
    func stravaSaveTask(completion: @escaping (Bool) -> Void = {_ in}, task: BGTask? = nil) {
        
        var wasExpired: Bool = false
        
        let taskCompletionFunction: () -> Void = {
            DispatchQueue.main.async {
                self.stravaSaveInProgress = false
            }
            if wasExpired {
                completion(false)
            } else {
                DispatchQueue.main.async {
                    completion(true)
                    self.stravaSaveCompleteDate = Date.now
                    UserDefaults.standard.set(self.stravaSaveCompleteDate, forKey: "stravaSaveCompleteDate")
                }

            }
        }
    

        logger.info("Running Strava Save task")

        if let task = task as? BGAppRefreshTask {
            logger.info("Task is BGAppRefreshTask")
            // Check the expiration handler to confirm job completion.
            task.expirationHandler = {
                self.logger.info("Task expired")
                wasExpired = true
                taskCompletionFunction()
                
            }
        }
        
        logger.info("BGAppRefreshTask Strava Save Complete!")
        taskCompletionFunction()

    }

    
    func activityAnalysisTask(completion: @escaping (Bool) -> Void = {_ in}, task: BGTask? = nil) {
        
        var wasExpired: Bool = false
        
        let taskCompletionFunction: () -> Void = {
            DispatchQueue.main.async {
                self.activityAnalysisInProgress = false
            }
            if wasExpired {
                completion(false)
            } else {
                DispatchQueue.main.async {
                    completion(true)
                    self.activityAnalysisCompleteDate = Date.now
                    UserDefaults.standard.set(self.activityAnalysisCompleteDate, forKey: "activityAnalysisCompleteDate")
                }

            }
        }
    

        logger.info("Running Activity Analysis task")

        if let task = task as? BGProcessingTask {
            logger.info("Task is BGProcessingTask")
            // Check the expiration handler to confirm job completion.
            task.expirationHandler = {
                self.logger.info("Task expired")
                wasExpired = true
                taskCompletionFunction()
                
            }
        }
        
        logger.info("BGProcessingTask Activity Analysis Complete!")
        taskCompletionFunction()

    }
    
    
    func buildStatisticsTask(completion: @escaping (Bool) -> Void = {_ in}, task: BGTask? = nil) {
    
        var progress: Progress?
        var wasExpired: Bool = false
        var cloudKitOperation: CKBlockProcessAllActivityRecords?
        
        let taskCompletionFunction: () -> Void = {
            DispatchQueue.main.async {
                self.refreshInProgress = false
            }
            if wasExpired {
                completion(false)
            } else {
                self.copyTempStatsToLive()
                self.statsBuckets.writeToCK(successCompletion: {
                    completion(true)
                    DispatchQueue.main.async {
                        self.refreshCompleteDate = Date.now
                        UserDefaults.standard.set(self.refreshCompleteDate, forKey: "statisticsRefreshDate")
                    }
                    },
                    failureCompleation: {completion(false)})

            }
        }
        
        logger.info("Running stats rebuild")

        if let task = task as? BGContinuedProcessingTask {
            logger.info("Task is BGContinuedProcessingTask")
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
        
        // Clear out the current buckets
        statsBuckets.emptyTempBuckets()
        
        // Refill from cloudkit
        cloudKitOperation = CKBlockProcessAllActivityRecords(
            blockProcessFunction: {ckRecords in

                self.addActivitiesToTempStats(ckRecordList: ckRecords)
                
                // update the live activity widget
                if let task = task as? BGContinuedProcessingTask {
                    task.updateTitle("Rebuilding all statistics",
                                     subtitle: "Completed \(progress!.completedUnitCount)")
 
                }

            },
            completionFunction: taskCompletionFunction,
            progress: progress)
        
        cloudKitOperation!.execute()

    }
        
    
    @available(iOS 26.0, *)
    // Submit a background continued processing task to rebuild all statistics
    func submitBuildStatisticsTask() {
        
        if refreshInProgress {
            logger.info("Can't submit request, background processing already active.")
            return
        }
        refreshInProgress = true
        
        let request = BGContinuedProcessingTaskRequest(
            identifier: "MurrayNet.PulseWorkout-Phone-App.statsRebuild",
            title: "Rebuilding statistics", subtitle: "Starting...")

        logger.info("Submitting background task request")
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Successfully submitted background task request")

        } catch {
            logger.error("Failed to submit background task: \(error.localizedDescription)")
        }
        
    }
    
    
    // Submit a BGAppRefresh task to save to Strava
    func submitStravaSaveTask() {
        
        if stravaSaveInProgress {
            logger.info("Can't submit request, background processing already active.")
            return
        }
        stravaSaveInProgress = true
        
        let request = BGAppRefreshTaskRequest(
            identifier: "MurrayNet.PulseWorkout-Phone-App.stravaSave")

        request.earliestBeginDate = Date()
        
        logger.info("Submitting background task request")
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Successfully submitted background task request")
            self.stravaSaveSubmitDate = Date.now
            UserDefaults.standard.set(self.stravaSaveSubmitDate, forKey: "stravaSaveSubmitDate")


        } catch {
            logger.error("Failed to submit background task: \(error.localizedDescription)")
        }
        
    }
    
    
    // Submit a BGTask task to analyse activities
    func submitActivityAnalysisTask() {
        
        if activityAnalysisInProgress {
            logger.info("Can't submit request, background processing already active.")
            return
        }
        activityAnalysisInProgress = true
        
        let request = BGProcessingTaskRequest(
            identifier: "MurrayNet.PulseWorkout-Phone-App.activityAnalysis")

        request.earliestBeginDate = Date()
        request.requiresExternalPower = false
        request.requiresNetworkConnectivity = true
        
        logger.info("Submitting background activity analysis task request")
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("Successfully background activity analysis task request")
            self.activityAnalysisSubmitDate = Date.now
            UserDefaults.standard.set(self.activityAnalysisSubmitDate, forKey: "activityAnalysisSubmitDate")


        } catch {
            logger.error("Failed to submit background activity analysis task: \(error.localizedDescription)")
        }
        
    }
    #endif
    
    
    /// Return full set of statistics buckers as Cloudkit Records
    func allCKRecords() -> [CKRecord] {
        
        return statsBuckets.asCKRecords()
        
    }
    
    
    /// Read statistics from cloudkit - refresh the cache
    func refresh(onRefreshCompletionFunc: @escaping () -> Void = {}) {

        CKStatisticBucketQueryOperation(blockCompletionFunction: refreshCompletion).execute()
        
        self.onRefreshCompletionFunc = onRefreshCompletionFunc
    }
    
    
    func refreshCompletion(ckRecordList: [CKRecord]) -> Void {
        
        statsBuckets.createElementsFromCKRecords(ckRecordList: ckRecordList)

        // Update the UI data
        reset()
        
        onRefreshCompletionFunc()
    }
    
    
    /// Add list of activity CKRecords to temp stats buckets
    func addActivitiesToTempStats(ckRecordList: [CKRecord]) -> Void {

        let activityList = ckRecordList.map( {ActivityRecord(fromCKRecord: $0, fetchtrackData: false)})
        _ = activityList.map( {statsBuckets.addActivityToTemp($0) })
        
    }
    
    
    func copyTempStatsToLive() {

        statsBuckets.copyTempToElements()
        
        // Do NOT write to CloudKit - the caller is responsible for this
        _ = statsBuckets.write(copyToCK: false)
        
        reset()
    }
    
    
    /// Add single activity record to stats buckets
    func addActivityToStats(activity: ActivityRecord) -> Void {
        
        logger.info("Adding \(activity.name) to statistics")
        statsBuckets.addActivity(activity)
        
        // Do NOT write to CloudKit - the caller is responsible for this
        _ = statsBuckets.write(copyToCK: false)
        
        reset()
        
    }
    
    
    /// Remove single activity record from stats buckets
    func removeActivityFromStats(activity: ActivityRecord) -> Void {
        
        statsBuckets.removeActivity(activity)
  
        // Do NOT write to CloudKit - the caller is responsible for this
        _ = statsBuckets.write(copyToCK: false)
        
        reset()
        
    }
    
}

