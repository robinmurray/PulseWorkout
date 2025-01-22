//
//  ActivityProfile.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 19/02/2023.
//

import Foundation
import CloudKit
import os


/** The main data structure for maintaining workout / profile infromation */
struct ActivityProfile: Codable, Identifiable, Equatable {
   

    
    /// The unique identifier of the activity profile.
    var id: UUID?

    /// The name of the activity profile.
    var name: String
    
    /// Apple HK workout type.
    var workoutTypeId: UInt
    
    /// Apple HK workout location.
    var workoutLocationId: Int
    
    /// Whether to raise alarm on HR over high limit.
    var hiLimitAlarmActive: Bool
    
    /// Value of HR high limit.
    var hiLimitAlarm: Int
    
    /// Whether to raise alarm on HR under low limit.
    var loLimitAlarmActive: Bool
    
    /// Value of HR low limit.
    var loLimitAlarm: Int
    
    /// Whether to play alarm sound on HR alarm limits.
    var playSound: Bool
    
    /// Whether to create haptic on HR alarm limits.
    var playHaptic: Bool
    
    /// Whether to repeat alarms / haptics when in alarm state, or just play alarm when entering alarm state.
    var constantRepeat: Bool
    
    /// Whether to initiate water lock on screen when workout is active.
    var lockScreen: Bool

    /// The date the profile was last used or edited.
    var lastUsed: Date?
    
    /// Whether to enable auto-pause on this profile
    var autoPause: Bool

    init(name: String,
         workoutTypeId: UInt,
         workoutLocationId: Int,
         hiLimitAlarmActive: Bool,
         hiLimitAlarm: Int,
         loLimitAlarmActive: Bool,
         loLimitAlarm: Int,
         playSound: Bool,
         playHaptic: Bool,
         constantRepeat: Bool,
         lockScreen: Bool,
         autoPause: Bool) {
        
        self.id = UUID()
        self.name = name
        self.workoutTypeId = workoutTypeId
        self.workoutLocationId = workoutLocationId
        self.hiLimitAlarmActive = hiLimitAlarmActive
        self.hiLimitAlarm = hiLimitAlarm
        self.loLimitAlarmActive = loLimitAlarmActive
        self.loLimitAlarm = loLimitAlarm
        self.playSound = playSound
        self.playHaptic = playHaptic
        self.constantRepeat = constantRepeat
        self.lockScreen = lockScreen
        self.autoPause = autoPause
        
    }
    
    /// Initialise profile from CKRecord
    init(record: CKRecord) {
        
        let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                            category: "ActivityProfile")

        if record.recordType != "ActivityProfile" {
            logger.error("Incorrect record type for Activity Profile")

        }

        id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        name = record["name"] ?? "" as String
        workoutTypeId = record["workoutTypeId"] ?? 1 as UInt
        workoutLocationId = record["workoutLocationId"] ?? 1 as Int
        hiLimitAlarmActive = record["hiLimitAlarmActive"] ?? false as Bool
        hiLimitAlarm = record["hiLimitAlarm"] ?? 140 as Int
        loLimitAlarmActive = record["loLimitAlarmActive"] ?? false as Bool
        loLimitAlarm = record["loLimitAlarm"] ?? 120 as Int
        playSound = record["playSound"] ?? false as Bool
        playHaptic = record["playHaptic"] ?? false as Bool
        constantRepeat = record["constantRepeat"] ?? false as Bool
        lockScreen = record["lockScreen"] ?? false as Bool
        lastUsed = record["lastUsed"] as Date?
        autoPause = record["autoPause"] ?? true as Bool
        
    }
    
    
    /// Convert device data to CKRecord
    func asCKRecord(recordID: CKRecord.ID) -> CKRecord {
        let recordType = "ActivityProfile"
//        let recordID: CKRecord.ID = CKRecordID()
        let record = CKRecord(recordType: recordType, recordID: recordID)
        record["name"] = name as CKRecordValue
        record["workoutTypeId"] = workoutTypeId as CKRecordValue
        record["workoutLocationId"] = workoutLocationId as CKRecordValue
        record["hiLimitAlarmActive"] = hiLimitAlarmActive as CKRecordValue
        record["hiLimitAlarm"] = hiLimitAlarm as CKRecordValue
        record["loLimitAlarmActive"] = loLimitAlarmActive as CKRecordValue
        record["loLimitAlarm"] = loLimitAlarm as CKRecordValue
        record["playSound"] = playSound as CKRecordValue
        record["playHaptic"] = playHaptic as CKRecordValue
        record["constantRepeat"] = constantRepeat as CKRecordValue
        record["lockScreen"] = lockScreen as CKRecordValue
        record["lastUsed"] = lastUsed as CKRecordValue?
        record["autoPause"] = autoPause as CKRecordValue
        
        return record
    }
}


