//
//  ActivityProfile.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 19/02/2023.
//

import Foundation
import HealthKit


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

}



class ActivityProfiles: NSObject, ObservableObject {

    @Published var profiles: [ActivityProfile] = []
    private var lastSavedProfiles: [ActivityProfile] = []
    
    override init() {

        super.init()

        // Read in all profiles from user defaults
        self.read()
        
        // if no profiles set up then create defaults to get started!
        if profiles.count == 0 {
            self.addDefaults()
            self.write()
        }

    }
    
    func addNew() -> UUID {
        return add(activityProfile: ActivityProfile ( name: "New Profile",
                                               workoutTypeId: HKWorkoutActivityType.cycling.rawValue,
                                               workoutLocationId: HKWorkoutSessionLocationType.outdoor.rawValue,
                                               hiLimitAlarmActive: false,
                                               hiLimitAlarm: 140,
                                               loLimitAlarmActive: false,
                                               loLimitAlarm: 100,
                                               playSound: false,
                                               playHaptic: false,
                                               constantRepeat: false,
                                               lockScreen: false))
    }


    /// Add a set of default profiles to get application stared.
    /// Adds "Race", "Aerobic" and "Recovery" activity profiles.
    func addDefaults() {

        _ = add(activityProfile: ActivityProfile ( name: "Race",
                                               workoutTypeId: HKWorkoutActivityType.cycling.rawValue,
                                               workoutLocationId: HKWorkoutSessionLocationType.outdoor.rawValue,
                                               hiLimitAlarmActive: true,
                                               hiLimitAlarm: 160,
                                               loLimitAlarmActive: false,
                                               loLimitAlarm: 100,
                                               playSound: true,
                                               playHaptic: true,
                                               constantRepeat: false,
                                               lockScreen: false))

        _ = add(activityProfile: ActivityProfile ( name: "Aerobic",
                                               workoutTypeId: HKWorkoutActivityType.cycling.rawValue,
                                               workoutLocationId: HKWorkoutSessionLocationType.outdoor.rawValue,
                                               hiLimitAlarmActive: true,
                                               hiLimitAlarm: 140,
                                               loLimitAlarmActive: false,
                                               loLimitAlarm: 100,
                                               playSound: true,
                                               playHaptic: true,
                                               constantRepeat: false,
                                               lockScreen: false))

        _ = add(activityProfile: ActivityProfile ( name: "Recovery",
                                               workoutTypeId: HKWorkoutActivityType.cycling.rawValue,
                                               workoutLocationId: HKWorkoutSessionLocationType.outdoor.rawValue,
                                               hiLimitAlarmActive: true,
                                               hiLimitAlarm: 130,
                                               loLimitAlarmActive: false,
                                               loLimitAlarm: 100,
                                               playSound: true,
                                               playHaptic: true,
                                               constantRepeat: false,
                                               lockScreen: false))

    }

    /// Add an activity profile to the list of profiles and write profiles back to userDefaults.
    func add(activityProfile: ActivityProfile) -> UUID {
        
        var newActivityProfile = activityProfile
        if newActivityProfile.id == nil {
            newActivityProfile.id = UUID()
        }
        newActivityProfile.lastUsed = Date()
        
        profiles.append(newActivityProfile)

        self.write()
        
        return newActivityProfile.id!
    }
    
    /// Delete an activity profile from profiles.
    func remove(activityProfile: ActivityProfile) {
        
        // don't allow deletion fo all profiles!
        if profiles.count == 1 {
            return
        }
        
        for (index, profile) in profiles.enumerated() {
            if profile.id == activityProfile.id {
                profiles.remove(at: index)
                return
            }
        }
    }

    /// Update activity profile and write to userDefaults.
    /// If onlyIfChanged set then test that the profiles have changed before saving.
    func update(activityProfile: ActivityProfile, onlyIfChanged: Bool) {

        var updatedActivityProfile = activityProfile

        for (index, profile) in profiles.enumerated() {
            if profile.id == updatedActivityProfile.id {

                if (!onlyIfChanged || !(lastSavedProfiles == profiles)) {
                    updatedActivityProfile.lastUsed = Date()
                    profiles[index] = updatedActivityProfile
                    
                    self.write()
                }

                return
            }
        }
    }


    /// Return activity profile for a given profile id.
    func get(id: UUID) -> ActivityProfile? {

        for profile in profiles {
            if profile.id == id {
                return profile
            }
        }
        return nil
    }
    
    func read() {
        print("Trying decode profiles")
        
        // Initialise empty dictionary
        // try to read from userDefaults in to this - if fails then use defaults

        if let savedProfiles = UserDefaults.standard.object(forKey: "ActivityProfiles") as? Data {
            let decoder = JSONDecoder()
            if let loadedProfiles = try? decoder.decode(type(of: profiles), from: savedProfiles) {
                print(loadedProfiles)
                profiles = loadedProfiles
                lastSavedProfiles = loadedProfiles
                
            }
        }
    }

    
    
    func write() {
        
        print("Writing profile!")
        let epochDate = NSDate(timeIntervalSince1970: 0) as Date
        profiles = profiles.sorted(by: { $0.lastUsed ?? epochDate > $1.lastUsed ?? epochDate })
        lastSavedProfiles = profiles
        do {
            let data = try JSONEncoder().encode(profiles)
            let jsonString = String(data: data, encoding: .utf8)
            print("JSON : \(String(describing: jsonString))")
            UserDefaults.standard.set(data, forKey: "ActivityProfiles")
        } catch {
            print("Error enconding")
        }

    }
    
}



extension HKWorkoutActivityType: Identifiable {
    public var id: UInt {
        rawValue
    }
    
    var name: String {
        switch self {
        case .crossTraining:
            return "Cross Training"
        case .cycling:
            return "Cycling"
        case .mixedCardio:
            return "Mixed Cardio"
        case .paddleSports:
            return "Paddle Sports"
        case .rowing:
            return "Rowing"
        case .running:
            return "Running"
        case .walking:
            return "Walking"
        default:
            return ""
        }
    }
}


extension HKWorkoutSessionLocationType: Identifiable {
    public var id: Int {
        rawValue
    }
    
    var name: String {
        switch self {
        case .indoor:
            return "Indoor"
        case .outdoor:
            return "Outdoor"
        case .unknown:
            return "Unknown"
        default:
            return ""
        }
    }
    
    var label: String {
        switch self {
        case .unknown:
            return ""
        default:
            return self.name
        }
    }
}
