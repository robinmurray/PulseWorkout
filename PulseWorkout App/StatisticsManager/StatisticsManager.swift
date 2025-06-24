//
//  StatisticsManager.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 08/06/2025.
//

import Foundation
import os
import CloudKit




class StatisticsManager: ObservableObject {
    
    ///Access StatisticsManager through StatisticsManager.shared
    public static let shared = StatisticsManager()

    
    @Published var thisWeekDayBuckets: StatisticsBucketArray
    @Published var lastWeekDayBuckets: StatisticsBucketArray

    @Published var weekBuckets: StatisticsBucketArray
    @Published var quarterBuckets: StatisticsBucketArray

    @Published var yearBuckets: StatisticsBucketArray

    

    var statsBuckets: StatisticsBucketArray

    init() {
        self.statsBuckets = StatisticsBucketArray()
        self.thisWeekDayBuckets = statsBuckets.thisWeekDayBuckets()
        self.lastWeekDayBuckets = statsBuckets.lastWeekDayBuckets()
        self.weekBuckets = statsBuckets.weekBuckets()
        self.quarterBuckets = statsBuckets.quarterBuckets()
        self.yearBuckets = statsBuckets.yearBuckets()
        
        print("quarterbuckets: \(quarterBuckets.elements)")

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
    
    
    func thisWeek() -> StatisticsBucket {
        return weekBuckets.elements.last!
    }

    
    func lastWeek() -> StatisticsBucket {
        let weekCount = weekBuckets.elements.count
        let lastWeekIndex = max(weekCount - 2, 0)
        return weekBuckets.elements[lastWeekIndex]
    }
    
    
    func thisYear() -> StatisticsBucket {
        return yearBuckets.elements.last!
    }

    
    func lastYear() -> StatisticsBucket {
        return yearBuckets.elements.first!
    }
    
    
    func buildStatistics() {
        statsBuckets.emptyTempBuckets()
        
        CKActivityQueryOperation(startDate: nil,
                                 blockCompletionFunction: addActivitiesToStats,
                                 resultsLimit: 100,
                                 qualityOfService: .userInitiated).execute()
    }
    
    
    /// Add list of activity CKRecords to stats buckets
    func addActivitiesToStats(ckRecordList: [CKRecord]) -> Void {
        
        let activityList = ckRecordList.map( {ActivityRecord(fromCKRecord: $0)})
        _ = activityList.map( {statsBuckets.addActivityToTemp($0) })
        
        statsBuckets.copyTempToElements()
        
        _ = statsBuckets.write()
        
        reset()
        
    }
    
    
    /// Add single activity records to stats buckets
    func addActivityToStats(activity: ActivityRecord) -> Void {
        
        statsBuckets.addActivity(activity)
        
        _ = statsBuckets.write()
        
        reset()
        
    }
    
}

