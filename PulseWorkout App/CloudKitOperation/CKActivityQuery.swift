//
//  CKActivityQuery.swift
//  PulseWorkout
//
//  Created by Robin Murray on 10/04/2025.
//

import Foundation
import CloudKit
import os


class CKActivityQueryOperation: CloudKitOperation {
 
    var startDate: Date?
    var blockCompletionFunction: ([CKRecord]) -> Void
    var resultsLimit: Int
    var qualityOfService: QualityOfService
    
    
    init(startDate: Date?,
         blockCompletionFunction : @escaping ([CKRecord]) -> Void,
         resultsLimit: Int,
         qualityOfService: QualityOfService) {
        
        self.startDate = startDate
        self.blockCompletionFunction = blockCompletionFunction
        self.resultsLimit = resultsLimit
        self.qualityOfService = qualityOfService
        
    }
    
    
    /// Query definition for fetching activities from CloudKit
    func activityQuery(startDate: Date?) -> CKQueryOperation {
        
        var pred = NSPredicate(value: true)
        if startDate != nil {
            pred = NSPredicate(format: "startDateLocal < %@", startDate! as CVarArg)
        }
        let sort = NSSortDescriptor(key: "startDateLocal", ascending: false)
        let query = CKQuery(recordType: "Activity", predicate: pred)
        query.sortDescriptors = [sort]

        let operation = CKQueryOperation(query: query)

        operation.desiredKeys = ["name", "stravaType", "startDateLocal", "elapsedTime", "pausedTime", "movingTime",
                                 "activityDescription", "distance", "totalAscent", "totalDescent",
                                 "averageHeartRate", "averageCadence", "averagePower", "averageSpeed",
                                 "maxHeartRate", "maxCadence", "maxPower", "maxSpeed",
                                 "activeEnergy", "timeOverHiAlarm", "timeUnderLoAlarm", "hiHRLimit", "loHRLimit",
                                 "mapSnapshot", "stravaId", "stravaSaveStatus", "trackPointGap",
                                 "TSS", "FTP", "powerZoneLimits", "TSSbyPowerZone", "movingTimebyPowerZone",
                                 "TSSSummable", "TSSSummableByPowerZone", "intensityFactor", "normalisedPower", "estimatedVO2Max",
                                 "profileWeightKG", "profileMaxHR", "profileRestHR", "estimatedEPOC",
                                 "thesholdHR", "estimatedTSSbyHR", "HRZoneLimits", "TSSEstimatebyHRZone", "movingTimebyHRZone",
                                 "hasLocationData", "hasHRData", "hasPowerData", "loAltitudeMeters", "hiAltitudeMeters",
                                 "averageSegmentSize", "HRSegmentAverages", "powerSegmentAverages", "cadenceSegmentAverages",
                                 "altitudeImage", "tcx", "workoutTypeId"]

        
        return operation
        
    }
    
    func execute() {
        
        CKFetchRecordBlockOperation(query: activityQuery(startDate: self.startDate),
                                    blockCompletionFunction: self.blockCompletionFunction,
                                    resultsLimit: self.resultsLimit,
                                    qualityOfService: self.qualityOfService).execute()
        
    }
}
