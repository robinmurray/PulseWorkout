//
//  CKProcessAllActivityRecords.swift
//  PulseWorkout
//
//  Created by Robin Murray on 30/07/2025.
//

import Foundation
import CloudKit
import os


func testProcessAllActivityRecords(ckRecord: CKRecord, completionFunction: @escaping () -> Void) {
    
    let startDate = ckRecord["startDateLocal"] ?? Date() as Date
    print("StartDateLocal : \(startDate)")
    
    completionFunction()
}

class CKProcessAllActivityRecords: CloudKitOperation {
 
    var startDate: Date?
    var recordProcessFunction: (CKRecord, @escaping () -> Void) -> Void
    var completionFunction: () -> Void
    var asyncProgressNotifier: AsyncProgress?
    var resultsLimit: Int = 50
    var fetchedCKRecords: [CKRecord] = []
    var processedCount = 0
    
    
    init(recordProcessFunction : @escaping (CKRecord, @escaping () -> Void) -> Void,
         completionFunction: @escaping () -> Void = { },
         asyncProgressNotifier: AsyncProgress? = nil) {
        
        self.recordProcessFunction = recordProcessFunction
        self.asyncProgressNotifier = asyncProgressNotifier
        self.completionFunction = completionFunction
        super.init()
        self.recordProcessFunction = test

    }
    
    
    func getTotalAscent(activityRecord: ActivityRecord) -> Double {
        
        let altitudeData = activityRecord.trackPoints.filter({ $0.altitudeMeters != nil }).map( { $0.altitudeMeters ?? 0})
        if altitudeData.count > 1 {
            // altitudeChanges = array of ascnets & descents - descents are negative
            let altitudeChanges = zip(altitudeData, altitudeData.dropFirst()).map( {$1 - $0} )
            let ascents = altitudeChanges.filter({ $0 > 0 })
            return round(ascents.reduce(0, +) * 10) / 10
        }
        return 0
    }
    
    func test(ckRecord: CKRecord, completionFunction: @escaping () -> Void) {
        
//        let activity = ActivityRecord(fromCKRecord: ckRecord, fetchtrackData: false)
        
        let activity = ActivityRecord(fromCKRecord: ckRecord, fetchtrackData: true)
        
        

        logger.info("Updating \(activity.startDateLocal)")

        if !activity.trackPoints.isEmpty {
            activity.hasPowerData = !(activity.trackPoints.filter({ ($0.watts ?? 0) > 0}).isEmpty)
            activity.hasHRData = !(activity.trackPoints.filter({ ($0.heartRate ?? 0) > 0}).isEmpty)
            activity.hasLocationData = !(activity.trackPoints.filter({ ($0.latitude ?? 0) != 0}).isEmpty)
            activity.totalAscent = getTotalAscent(activityRecord: activity)
            
            activity.addActivityAnalysis()
        }
 
        activity.timeZone = TimeZone.current
        activity.GMTOffset = TimeZone.current.secondsFromGMT()
        activity.startDate = activity.startDateLocal.addingTimeInterval(-Double(activity.GMTOffset))
        
 
        CKForceUpdateOperation(ckRecord: activity.asCKRecord(addTrackData: false),
                               completionFunction: testCompletion).execute()



/*
        CKFetchRecordOperation(recordID: ckRecord.recordID,
                               completionFunction: testCompletionA,
                               completionFailureFunction: {self.logger.error("Fetch Failed")}).execute()
*/
    }
    
    func testCompletionA(record: CKRecord) {
        processNextRecord()
    }
    
    func testCompletion(ckRecordID: CKRecord.ID?) {

        let justTestFirstRecord: Bool = false
        
        if justTestFirstRecord {
            if let notifier = asyncProgressNotifier {
                notifier.complete()
            }
            completionFunction()
        }
        else {
            processNextRecord()
        }
        
    }
    
    func processNextRecord() {
        
        if processedCount == fetchedCKRecords.count {
            // If fetched full set of records then fetch next block
            if fetchedCKRecords.count == resultsLimit {
                startDate = fetchedCKRecords.last!["startDateLocal"] ?? Date() as Date
                execute()

            } else {
                if let notifier = asyncProgressNotifier {
                    notifier.complete()
                }
                completionFunction()
            }
            
        } else {
            processedCount += 1
            if let notifier = asyncProgressNotifier {
                let dateFormatter = DateFormatter()
                var formattedDate: String = "None"
                dateFormatter.dateFormat = "dd-MM-yyyy"
                if let thisDate = fetchedCKRecords[processedCount - 1]["startDateLocal"] as? Date {
                    formattedDate = dateFormatter.string(from: thisDate)
                }

                notifier.set(message: "Processing \(formattedDate)")
            }
            recordProcessFunction(fetchedCKRecords[processedCount - 1], processNextRecord)
        }

    }
    
    func fetchBlockCompletion(ckRecords: [CKRecord]) -> Void {

        fetchedCKRecords = ckRecords
        processedCount = 0
        processNextRecord()

    }


    func execute() {
        
        logger.info("Fetching block with startDate \(String(describing: self.startDate))")
        CKActivityQueryOperation(startDate: startDate,
                                 blockCompletionFunction : fetchBlockCompletion,
                                 resultsLimit: resultsLimit,
                                 qualityOfService: .userInitiated).execute()
        
        
    }
}

