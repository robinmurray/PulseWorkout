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
    var id: UUID
    var startDate: Date
    var endDate: Date
    var startDateString: String
    var endDateString: String
    var bucketType: Int
    var workoutTypeIds: [UInt]
    var activities: Double
    var activitiesByType: [Double]
    var distanceMeters: Double
    var distanceMetersByType: [Double]
    var time: Double
    var TSS: Double
    var TSSByZone: [Double]
    var timeByZone: [Double]
    
    init(startDate: Date, bucketType: BucketType) {
        
        self.id = UUID()
        self.startDate = startDate
        self.endDate = Calendar.current.date(byAdding: StatisticsBucketDuration[bucketType]!.unit,
                                             value: StatisticsBucketDuration[bucketType]!.count,
                                             to: startDate)!
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        dateFormatter.timeZone = .current
        self.startDateString = startDate.formatted(.iso8601
            .year()
            .month()
            .day())
        self.endDateString = endDate.formatted(.iso8601
            .year()
            .month()
            .day())
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
    

    
    // Create a statistics bucket as 7-day average from array of buckets - which must be of the same type
    init(bucketArray: [StatisticsBucket]) {
        
        // Initialise version in case of error - THIS SHOULD NOT BE RETURNED!
        self = StatisticsBucket(startDate: Date.now, bucketType: .day)
        
        // Now do the job for real!
        if let first = bucketArray.first {
            if bucketArray.allSatisfy({ $0.bucketType == first.bucketType }) {
                
                self.id = UUID()
                self.startDate = first.startDate
                self.endDate = bucketArray.last!.endDate
                
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withFullDate]
                dateFormatter.timeZone = .current
                self.startDateString = startDate.formatted(.iso8601
                    .year()
                    .month()
                    .day())
                self.endDateString = endDate.formatted(.iso8601
                    .year()
                    .month()
                    .day())
                self.bucketType = first.bucketType
                
                let days: Int = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1  // FIX TO DATE STRINGS!
                let daysToNow = Calendar.current.dateComponents([.day], from: startDate, to: Date.now).day ?? 1  // FIX TO DATE STRINGS!
                let divisorDays = max(min(days, daysToNow), 1)
                let divisor: Double = Double(divisorDays) / 7
                self.activities = bucketArray.reduce(0) { result, bucket
                    in
                    result + (bucket.activities / divisor)}

                self.distanceMeters = bucketArray.reduce(0) { result, bucket
                    in
                    result + (bucket.distanceMeters / divisor)}

                
                _ = bucketArray.map( {addTypedValues(newWorkoutTypeIds: $0.workoutTypeIds,
                                                     newActivities: $0.activitiesByType,
                                                     newDistanceMeters: $0.distanceMetersByType) })
                
                self.time = bucketArray.reduce(0) { result, bucket
                    in
                    result + (bucket.time / divisor)}
                self.TSS = bucketArray.reduce(0) { result, bucket
                    in
                    result + (bucket.TSS / divisor)}
                self.TSSByZone = bucketArray.reduce([0, 0, 0]) { result, bucket
                    in
                    zip(result, bucket.TSSByZone.map( { $0 / divisor } )).map(+)
                }
                
                self.timeByZone = bucketArray.reduce([0, 0, 0]) { result, bucket
                    in
                    zip(result, bucket.timeByZone.map( { $0 / divisor } )).map(+)
                }
            }
        }

    }
    
    
    /// Convert bucket to CKRecord, also allow properties to be addressed as a dictionary...
    func asCKRecord() -> CKRecord {

        let ckRecord = CKRecord(recordType: "StatisticBucket", recordID: CloudKitOperation().getCKRecordID())
        ckRecord["startDate"] = startDate as CKRecordValue
        ckRecord["endDate"] = endDate as CKRecordValue
        ckRecord["startDateString"] = startDateString as CKRecordValue
        ckRecord["endDateString"] = endDateString as CKRecordValue
        ckRecord["bucketType"] = bucketType as CKRecordValue
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

