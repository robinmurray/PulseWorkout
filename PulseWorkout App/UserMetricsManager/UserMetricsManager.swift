//
//  UserMetricsManager.swift
//  PulseWorkout
//
//  Created by Robin Murray on 17/04/2025.
//

import Foundation
import os
import CloudKit
import Combine


class UserMetricsManager: NSObject, ObservableObject  {
        
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "UserMetricsManager")
    
    /// Save settings to CloudKit
    func saveToCloudKit(ckRecord: CKRecord, completionFunction: @escaping (CKRecord.ID) -> Void) {
        CKSaveOperation(recordsToSave: [ckRecord],
                        recordSaveSuccessCompletionFunction: completionFunction).execute()
    }
    
    /// Get most recent metric record from cloudkit for given type
    func getLatestFromCK(recordType: String, completionFunction: @escaping ([CKRecord]) -> Void) {
        
        CKUserMetricQueryOperation(recordType: recordType,
                                   completionFunction: completionFunction).execute()
    }
}


class UserPowerMetrics: UserMetricsManager{
    
    let CK_RECORD_TYPE = "UserMetrics_Power"
    
    let storedFTPKey = "UserMetrics_Power_CurrentFTP"
    let storedPowerZoneLimitsKey = "UserMetrics_Power_PowerZoneLimits"
    let storedStartDateKey = "UserMetrics_Power_StartDate"

    @Published var metricsStartDate: Date
    @Published var currentFTP: Int
    @Published var powerZoneLimits: [Int]
    let defaultPowerZoneRatios = [0, 0.55, 0.75, 0.9, 1.05, 1.2]
    var copiedFrom: UserPowerMetrics?


    
    override init() {
        
        // Set up temporary values to keep compiler happy!
        currentFTP = 0
        metricsStartDate = Date()
        powerZoneLimits = []
        
        super.init()
        
        let storedFTP = UserDefaults.standard.integer(forKey: storedFTPKey)
        currentFTP = storedFTP == 0 ? 200 : storedFTP

        metricsStartDate = Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: storedStartDateKey))
        
        let FTPforCalc = currentFTP
        let storedLimits = UserDefaults.standard.array(forKey: storedPowerZoneLimitsKey)
        
        powerZoneLimits = defaultPowerZoneRatios.map({ Int(round($0 * Double(FTPforCalc))) })
        if let limits = storedLimits {
            if limits.count == defaultPowerZoneRatios.count {
                
                // if stored value cannot be coerced to an integer, take the default value
                let limitOrDefault = zip(limits, powerZoneLimits)
                powerZoneLimits = limitOrDefault.map({ $0 as? Int ?? $1 })
                
            }
            
        }
        
        // Now see if can fetch fom CK
        getLatestFromCK(recordType: CK_RECORD_TYPE,
                        completionFunction: self.setFromLatestCKRecord)
        
    }

    
    /// initialise a new metric set by copying existing one and setting start date to now
    init(fromUserPowerMetrics: UserPowerMetrics) {
        
        currentFTP = fromUserPowerMetrics.currentFTP
        powerZoneLimits = fromUserPowerMetrics.powerZoneLimits
        metricsStartDate = Date.now
        copiedFrom = fromUserPowerMetrics

    }
    
    
    /// If this record was copied from another record, then being used as temporary edit record
    /// If record has been changed then copy back to originator and force save
    func saveBackIfChanged() {
        
        if let parentRecord = copiedFrom {
            if (currentFTP != parentRecord.currentFTP) ||
                (powerZoneLimits != parentRecord.powerZoneLimits) {
                parentRecord.currentFTP = currentFTP
                parentRecord.powerZoneLimits = powerZoneLimits
                parentRecord.metricsStartDate = metricsStartDate
                
                parentRecord.save()
            }
        }
    }
    
    
    func getMetricsStartDateFromUserDefaults() -> Date {
        
        return Date(timeIntervalSince1970: UserDefaults.standard.double(forKey: storedStartDateKey))
        
    }
    
    
    func setFromLatestCKRecord(records: [CKRecord]) -> Void {
        
        if let latestRecord = records.first {
            fromCKRecord(ckRecord: latestRecord)
            saveToUserDefaults()
        }
    }
    
    
    /// Save to cloudkit, then update user defaults if latest record
    func save() {
        saveToCloudKit(ckRecord: asCKRecord(),
                       completionFunction: {_ in self.testSaveToUserDefaults()})
    }
    
    
    /// Update user defaults if latest record
    func testSaveToUserDefaults() {
        // If metrics are later date than locally stored latest version, then update
        if metricsStartDate > getMetricsStartDateFromUserDefaults() {
            saveToUserDefaults()
        }
    }
    
    
    func saveToUserDefaults() {
        
        UserDefaults.standard.set(metricsStartDate.timeIntervalSince1970, forKey: storedStartDateKey)
        UserDefaults.standard.set(currentFTP, forKey: storedFTPKey)
        UserDefaults.standard.set(powerZoneLimits, forKey: storedPowerZoneLimitsKey)

    }
    
    
    /// Convert  data to CKRecord
    func asCKRecord() -> CKRecord {

        let record = CKRecord(recordType: CK_RECORD_TYPE, recordID: CloudKitOperation().getCKRecordID())
        
        // Copy values to CKRecord
        record["metricsStartDate"] = metricsStartDate as CKRecordValue
        record["currentFTP"] = currentFTP as CKRecordValue
        record["profilePowerZoneLimits"] = powerZoneLimits as CKRecordValue
        return record
    }
    
    
    /// Convert CKRecord to data
    func fromCKRecord(ckRecord: CKRecord) {
        
        if ckRecord.recordType != CK_RECORD_TYPE {
            logger.error("Incorrect record type for POWER METRICS")
            return
        }
        
        // Copy values from CKRecord...
        metricsStartDate = ckRecord["metricsStartDate"] as? Date ?? Date()
        currentFTP = ckRecord["currentFTP"] as? Int ?? 200
        powerZoneLimits = ckRecord["powerZoneLimits"] as? [Int] ?? defaultPowerZoneRatios.map({ Int(round($0 * Double(currentFTP))) })
        
        // If metrics are later date than locally stored latest version, then update
        testSaveToUserDefaults()

    }

    
    func calculatePowerZonesFromFTP() {

        powerZoneLimits = defaultPowerZoneRatios.map({ Int(round($0 * Double(currentFTP))) })

    }
}


class UserHRMetrics: UserMetricsManager{
    
    let CK_RECORD_TYPE = "UserMetrics_HR"
    
}
