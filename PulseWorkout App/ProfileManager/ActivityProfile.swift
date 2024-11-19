//
//  ActivityProfile.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 19/02/2023.
//

import Foundation




/** The main data structure for maintaining workout / profile infromation */
struct ActivityProfile: Codable, Identifiable, Equatable {
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
    
    /// The unique identifier of the activity profile.
    var id: UUID?
    
    /// The date the profile was last used or edited.
    var lastUsed: Date?
    
    /// Whether to enable auto-pause on this profile
    var autoPause: Bool

}


