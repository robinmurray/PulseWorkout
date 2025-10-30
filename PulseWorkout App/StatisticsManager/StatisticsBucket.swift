//
//  StatisticsBucket.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 22/06/2025.
//

import Foundation
import CloudKit
import HealthKit
import SwiftUI




struct StatisticsBucket: Codable {
    
    /// The identifier for the bucket - has custom builder so as to maintain stable identifiers for buckets
    var id: String
    
    /// Start date for statistic bucket as a GMT-based (timezone erased) date
    var startDate: Date
    
    /// End date for statistic bucket as a GMT-based (timezone erased) date
    var endDate: Date
    
    /// The bucket type - raw value of BucketType
    var bucketType: Int
    
    /// The list of workout type ids that are present in this bucket - used as keys for activitiesByType and distanceMetersByType
    var workoutTypeIds: [UInt]
    
    /// The number of activities in this bucket
    var activities: Double
    
    /// List of activiites by Workout Type - in order of type list in workoutTypeIds
    var activitiesByType: [Double]
    
    /// Total distance in this bucket
    var distanceMeters: Double
    
    /// List of activiites by Workout Type - in order of type list in workoutTypeIds
    var distanceMetersByType: [Double]
    
    /// Total time
    var time: Double
    
    /// Total TSS
    var TSS: Double
    
    /// TSS by power zone (or HR zone if no power data)
    var TSSByZone: [Double]
    
    /// Time by HR Zone
    var timeByZone: [Double]
    
    
    mutating func setId(index: Int)  {
        self.id =  "statBucket-type:\(bucketType)-index:\(index)"
    }
    
    
    /// Initialiser for statisticsBucket
    ///
    /// startDate: Start date for bucket
    /// bucketType: The type of bucket (day, week , etc)
    /// index: Rolling index of buckets within the bucket type - used to create stable ids for the buckets
    init(startDate: Date, endDate: Date, bucketType: BucketType, index: Int) {
        
        self.id = ""
        self.startDate = startDate
        let nonGMTEndDate = Calendar.current.date(byAdding: StatisticsBucketDuration[bucketType]!.unit,
                                                             value: StatisticsBucketDuration[bucketType]!.count,
                                                             to: startDate)!
        self.endDate = nonGMTEndDate.addingTimeInterval(TimeInterval(Calendar.current.timeZone.secondsFromGMT(for: nonGMTEndDate)) -
                                                        TimeInterval(Calendar.current.timeZone.secondsFromGMT(for: startDate)))
        

        self.bucketType = bucketType.rawValue
        self.workoutTypeIds = []
        self.activities = 0
        self.activitiesByType = []
        self.distanceMeters = 0
        self.distanceMetersByType = []
        self.time = 0
        self.TSS = 0
        self.TSSByZone = [0, 0, 0]
        self.timeByZone = [0, 0, 0]
        setId(index: index)       // Set stable id for the bucket
        
    }

    
    /// Constructor from CKRecord
    init(fromCKRecord: CKRecord) {
        id = fromCKRecord.recordID.recordName
        startDate = fromCKRecord["startDate"] ?? Date.now
        endDate = fromCKRecord["endDate"] ?? Date.now
        bucketType = fromCKRecord["bucketType"] ?? 1
        workoutTypeIds = fromCKRecord["workoutTypeIds"] ?? []
        activities = fromCKRecord["activities"] ?? 0
        activitiesByType = fromCKRecord["activitiesByType"] ?? []
        distanceMeters = fromCKRecord["distanceMeters"] ?? 0
        distanceMetersByType = fromCKRecord["distanceMetersByType"] ?? []
        time = fromCKRecord["time"] ?? 0
        TSS = fromCKRecord["TSS"] ?? 0
        TSSByZone = fromCKRecord["TSSByZone"] ?? []
        timeByZone = fromCKRecord["timeByZone"] ?? []
        

    }
    
    mutating func addTypedValues( newWorkoutTypeIds: [UInt], newActivities: [Double], newDistanceMeters: [Double]) {
        
        for (newIndex, id) in newWorkoutTypeIds.enumerated() {
            if self.workoutTypeIds.firstIndex(of: id) == nil {
                let index = self.workoutTypeIds.firstIndex(where: {$0 > id}) ?? self.workoutTypeIds.endIndex
                self.workoutTypeIds.insert(id, at: index)
                self.activitiesByType.insert(0, at: index)
                self.distanceMetersByType.insert(0, at: index)
                
            }
            if let index = self.workoutTypeIds.firstIndex(of: id) {
                self.activitiesByType[index] += newActivities[newIndex]
                self.distanceMetersByType[index] += newDistanceMeters[newIndex]
            }
        }
    }
    
    
    mutating func removeTypedValues(workoutTypeIds: [UInt], activities: [Double], distanceMeters: [Double]) {
        
        for (removalIndex, id) in workoutTypeIds.enumerated() {
            if let index = self.workoutTypeIds.firstIndex(of: id) {
                
                self.activitiesByType[index] = max(0, self.activitiesByType[index] - activities[removalIndex])
                self.distanceMetersByType[index] = max(0, self.distanceMetersByType[index] - distanceMeters[removalIndex])
                
                // If no activities of this type left, remove the type and entries...
                if self.activitiesByType[index] == 0 {
                    self.workoutTypeIds.remove(at: index)
                    self.activitiesByType.remove(at: index)
                    self.distanceMetersByType.remove(at: index)
                }
            }
        }
    }
    
    
    /// Convert bucket to CKRecord, also allow properties to be addressed as a dictionary...
    func asCKRecord() -> CKRecord {

        let ckRecord = CKRecord(recordType: "StatisticBucket", recordID: CloudKitOperation().getCKRecordID(recordName: id))
        ckRecord["startDate"] = startDate as CKRecordValue
        ckRecord["endDate"] = endDate as CKRecordValue
        ckRecord["bucketType"] = bucketType as CKRecordValue
        ckRecord["workoutTypeIds"] = workoutTypeIds as CKRecordValue
        ckRecord["activities"] = activities as CKRecordValue
        ckRecord["activitiesByType"] = activitiesByType as CKRecordValue
        ckRecord["distanceMeters"] = distanceMeters as CKRecordValue
        ckRecord["distanceMetersByType"] = distanceMetersByType as CKRecordValue
        ckRecord["time"] = time as CKRecordValue
        ckRecord["TSS"] = TSS as CKRecordValue
        ckRecord["TSSByZone"] = TSSByZone as CKRecordValue
        ckRecord["timeByZone"] = timeByZone as CKRecordValue

        return ckRecord

    }
    
}

