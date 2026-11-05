//
//  BGFetchParameters.swift
//  PulseWorkout
//
//  Created by Robin Murray on 06/10/2026.
//

import Foundation
import BackgroundTasks


/// Structure of parameters to manage background Strava refresh
/// Persisted to UserDefaults
class BGFetchParameters: NSObject, Codable, ObservableObject {
    
    /// Is a refresh in progress
    @Published var inProgress: Bool
    
    /// Date background task was submitted
    @Published var submitDate: Date?
    
    /// Date to fetch records back to
    @Published var earliestFetchDate: Date?
    
    /// Current start date for page being fetched
    @Published var pageStartDate: Date?
    
    /// Current end date for page being fetched
    @Published var pageEndDate: Date?
    
    /// Total number of pages fetched so far
    @Published var pagesCompleted: Int
    
    /// page size for record fetch
    @Published var pageSize: Int
    
    /// Total number of records processed so far
    @Published var recordsCompleted: Int
    
    /// Number of retries on this page
    @Published var retryCount: Int
    
    /// Highest number of retries on any page
    @Published var highestRetryCount: Int
    
    /// Total number of retries in the entire operation
    @Published var totalRetries: Int
    
    /// Maximum retries allowed on this page
    @Published var maxRetries: Int
    
    /// If complete - the completion date
    @Published var completeDate: Date?
    
    /// If failed - the failure date
    @Published var failedDate: Date?
    
    /// Has the operation been cancelled
    @Published var cancelled: Bool
    
    /// If cancelled, the canceallation date
    @Published var cancelledDate: Date?
    
    /// Delay for earliest start time for next BGTask submission in seconds
    @Published var delay: Double
    
    /// Key to be used for saving parameters to UserDefaults
    var userDefaultsKey: String
    
    enum CodingKeys: String, CodingKey {
        case inProgress, submitDate, earliestFetchDate, pageStartDate, pageEndDate, pagesCompleted, pageSize, recordsCompleted, retryCount, highestRetryCount,
        totalRetries, maxRetries, completeDate, failedDate, cancelled, cancelledDate, delay, userDefaultsKey
    }
    
    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let inProgress = try container.decode(Bool.self, forKey: .inProgress)
        let submitDate = try container.decodeIfPresent(Date.self, forKey: .submitDate)
        let earliestFetchDate = try container.decodeIfPresent(Date.self, forKey: .earliestFetchDate)
        let pageStartDate = try container.decodeIfPresent(Date.self, forKey: .pageStartDate)
        let pageEndDate = try container.decodeIfPresent(Date.self, forKey: .pageEndDate)
        let pagesCompleted = try container.decode(Int.self, forKey: .pagesCompleted)
        let pageSize = try container.decode(Int.self, forKey: .pageSize)
        let recordsCompleted = try container.decode(Int.self, forKey: .recordsCompleted)
        let retryCount = try container.decode(Int.self, forKey: .retryCount)
        let highestRetryCount = try container.decode(Int.self, forKey: .highestRetryCount)
        let totalRetries = try container.decode(Int.self, forKey: .totalRetries)
        let maxRetries = try container.decode(Int.self, forKey: .maxRetries)
        let completeDate = try container.decodeIfPresent(Date.self, forKey: .completeDate)
        let failedDate = try container.decodeIfPresent(Date.self, forKey: .failedDate)
        let cancelled = try container.decode(Bool.self, forKey: .cancelled)
        let cancelledDate = try container.decodeIfPresent(Date.self, forKey: .cancelledDate)
        let delay = try container.decode(Double.self, forKey: .delay)
        let userDefaultsKey = try container.decode(String.self, forKey: .userDefaultsKey)
        
        self.init(userDefaultsKey: userDefaultsKey)
        // Assign decoded values to @Published properties
        self.inProgress = inProgress
        self.submitDate = submitDate
        self.earliestFetchDate = earliestFetchDate
        self.pageStartDate = pageStartDate
        self.pageEndDate = pageEndDate
        self.pagesCompleted = pagesCompleted
        self.pageSize = pageSize
        self.recordsCompleted = recordsCompleted
        self.retryCount = retryCount
        self.highestRetryCount = highestRetryCount
        self.totalRetries = totalRetries
        self.maxRetries = maxRetries
        self.completeDate = completeDate
        self.failedDate = failedDate
        self.cancelled = cancelled
        self.cancelledDate = cancelledDate
        self.delay = delay
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(inProgress, forKey: .inProgress)
        try container.encodeIfPresent(submitDate, forKey: .submitDate)
        try container.encodeIfPresent(earliestFetchDate, forKey: .earliestFetchDate)
        try container.encodeIfPresent(pageStartDate, forKey: .pageStartDate)
        try container.encodeIfPresent(pageEndDate, forKey: .pageEndDate)
        try container.encode(pagesCompleted, forKey: .pagesCompleted)
        try container.encode(pageSize, forKey: .pageSize)
        try container.encode(recordsCompleted, forKey: .recordsCompleted )
        try container.encode(retryCount, forKey: .retryCount)
        try container.encode(highestRetryCount, forKey: .highestRetryCount)
        try container.encode(totalRetries, forKey: .totalRetries)
        try container.encode(maxRetries, forKey: .maxRetries)
        try container.encodeIfPresent(completeDate, forKey: .completeDate)
        try container.encodeIfPresent(failedDate, forKey: .failedDate)
        try container.encode(cancelled, forKey: .cancelled)
        try container.encodeIfPresent(cancelledDate, forKey: .cancelledDate)
        try container.encode(delay, forKey: .delay)
        try container.encode(userDefaultsKey, forKey: .userDefaultsKey)
    }
    
    init(userDefaultsKey: String) {
        inProgress = false
        submitDate = nil
        earliestFetchDate = nil
        pageStartDate = nil
        pageEndDate = nil
        pagesCompleted = 0
        pageSize = 1
        recordsCompleted = 0
        retryCount = 0
        highestRetryCount = 0
        totalRetries = 0
        maxRetries = 5
        completeDate = nil
        failedDate = nil
        cancelled = false
        cancelledDate = nil
        delay = 15 * 60
        self.userDefaultsKey = userDefaultsKey

    }
    
    
    override var description: String {
        return "submitDate: \(submitDate, default: "None"), pageStartDate: \(pageStartDate, default: "None"), pagesCompleted: \(pagesCompleted)"
    }
    
    /// Persist parameters to UserDefaults
    func save() {
        do {
            let data = try JSONEncoder().encode(self)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to encode BG processing parameters: \(error.localizedDescription)")
        }
    }
    
    
    /// Retrieve parameters from UserDefaults
    func read() {
        
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                let params = try JSONDecoder().decode(BGFetchParameters.self, from: data)
                inProgress = params.inProgress
                submitDate = params.submitDate
                earliestFetchDate = params.earliestFetchDate
                pageStartDate = params.pageStartDate
                pageEndDate = params.pageEndDate
                pagesCompleted = params.pagesCompleted
                pageSize = params.pageSize
                recordsCompleted = params.recordsCompleted
                retryCount = params.retryCount
                highestRetryCount = params.highestRetryCount
                totalRetries = params.totalRetries
                maxRetries = params.maxRetries
                completeDate = params.completeDate
                failedDate = params.failedDate
                cancelled = params.cancelled
                cancelledDate = params.cancelledDate
                delay = params.delay
                userDefaultsKey = params.userDefaultsKey
            } catch {
                print("Failed to decode BG processing parameters: \(error.localizedDescription)")
            }
        }
        
    }
    
    
    /// Initialise parameters for a new fetch task
    func new(pageStartDate: Date?,
             earliestFetchDate: Date?,
             maxRetries: Int = 5,
             delay: Double = 15 * 60,
             pageSize: Int = 1) {

        inProgress = false
        submitDate = nil
        self.earliestFetchDate = earliestFetchDate
        self.pageStartDate = pageStartDate
        if let psd = pageStartDate {
            pageEndDate = Calendar.current.date(byAdding: .day, value: -10, to: psd)
        }
        pagesCompleted = 0
        self.pageSize = pageSize
        recordsCompleted = 0
        retryCount = 0
        totalRetries = 0
        highestRetryCount = 0
        self.maxRetries = maxRetries
        completeDate = nil
        cancelled = false
        cancelledDate = nil
        self.delay = delay
        
        save()
    }
    
    
    /// Record task as submitted
    func submitted() {

        inProgress = true
        submitDate = Date.now
        save()
    }
    
    
    /// To be called when a page has been read successfully
    /// Returns false if full refresh is complete
    /// Returns true if should continue
    func pageReadSuccess(recordCount: Int? = nil, earliestRecord: Date? = nil) -> Bool {
        
        if cancelled {
            return false
        }
        
        pagesCompleted += 1
        recordsCompleted = pagesCompleted * pageSize
        retryCount = 0
        
        // Uses this if reading till gets no records - not using end date / earliestFetchDate
        if let readCount = recordCount {
            if readCount == 0 {
                // Finished!
                completeDate = Date.now
                inProgress = false
                save()
                return false
            }
            pageStartDate = earliestRecord!
            save()
            return true
        }

        pageStartDate = pageEndDate
        pageEndDate = Calendar.current.date(byAdding: .day, value: -10, to: pageStartDate!)!


        if pageStartDate! < earliestFetchDate! {
            completeDate = Date.now
            inProgress = false
            save()
            return false
        }
        
        save()
        return true
    }

    
    /// To be called when a page read has failed
    /// Returns false if retries exhausted and therefore overall failure
    /// Returns true if should continue
    func pageReadFailed() -> Bool {

        if cancelled {
            return false
        }

        retryCount += 1
        totalRetries += 1

        // Log the maximum number of retries
        if retryCount > highestRetryCount {
            highestRetryCount = retryCount
        }
        
        if retryCount > maxRetries {
            inProgress = false
            failedDate = Date.now
            save()
            return false
        }
        
        save()
        return true
    }

    
    /// To be called on non-specific failure
    /// Returns false if retries exhausted and therefore overall failure
    /// Returns true if should continue
    func failed() {
        
        inProgress = false
        failedDate = Date.now
        save()
    }

    
    /// Mark the task as cancelled.
    /// If task is in execution this will cause it not be re-submitted
    /// If task was pending, this should be called once the task has been cancelled from BG scheduler
    func cancelRequest() {

        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: "MurrayNet.PulseWorkout-Phone-App.fullStravaRefresh")

        cancelled = true
        cancelledDate = Date.now
        inProgress = false
        save()

    }
    
    
    /// Return true if task is currently in progress
    func isInProgress() -> Bool {

        return inProgress
    }
}

