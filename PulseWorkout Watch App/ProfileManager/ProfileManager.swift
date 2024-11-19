//
//  ProfileManager.swift
//  PulseWorkout
//
//  Created by Robin Murray on 19/11/2024.
//

import Foundation
import os
import HealthKit

class ProfileManager: NSObject, ObservableObject {

    @Published var profiles: [ActivityProfile] = []
    private var lastSavedProfiles: [ActivityProfile] = []
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "activityProfiles")
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
    
    func newProfile() -> ActivityProfile {
        
        return ActivityProfile (name: "New Profile",
                                workoutTypeId: HKWorkoutActivityType.cycling.rawValue,
                                workoutLocationId: HKWorkoutSessionLocationType.outdoor.rawValue,
                                hiLimitAlarmActive: false,
                                hiLimitAlarm: 140,
                                loLimitAlarmActive: false,
                                loLimitAlarm: 100,
                                playSound: false,
                                playHaptic: false,
                                constantRepeat: false,
                                lockScreen: false,
                                autoPause: true)
        
    }
    
    
    func addNew() -> Int {
        return add(activityProfile: newProfile())
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
                                                   lockScreen: false,
                                                   autoPause: true))

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
                                                   lockScreen: false,
                                                   autoPause: true))

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
                                                   lockScreen: false,
                                                   autoPause: true))

    }

    /// Add an activity profile to the list of profiles and write profiles back to userDefaults.
    func add(activityProfile: ActivityProfile) -> Int {
        
        var newActivityProfile = activityProfile
        if newActivityProfile.id == nil {
            newActivityProfile.id = UUID()
        }
        newActivityProfile.lastUsed = Date()
        
        profiles.insert(newActivityProfile, at: 0)

        self.write(sortBeforeWrite: false)
        
        // return index of new entry
        return (0)
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
                self.write()
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
                    
                    self.write(sortBeforeWrite: false)
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
        logger.debug("Trying decode profiles")
        
        // Initialise empty dictionary
        // try to read from userDefaults in to this - if fails then use defaults

        if let savedProfiles = UserDefaults.standard.object(forKey: "ActivityProfiles") as? Data {
            let decoder = JSONDecoder()
            if let loadedProfiles = try? decoder.decode(type(of: profiles), from: savedProfiles) {
                logger.debug("\(loadedProfiles)")
                profiles = loadedProfiles
                lastSavedProfiles = loadedProfiles
                
            }
        }
    }

    
    
    func write(sortBeforeWrite: Bool = true) {
        
        logger.debug("Writing profile!")
        if sortBeforeWrite {
            let epochDate = NSDate(timeIntervalSince1970: 0) as Date
            profiles = profiles.sorted(by: { $0.lastUsed ?? epochDate > $1.lastUsed ?? epochDate })
        }

        lastSavedProfiles = profiles
        do {
            let data = try JSONEncoder().encode(profiles)
            let jsonString = String(data: data, encoding: .utf8)
            logger.debug("JSON : \(String(describing: jsonString))")
            UserDefaults.standard.set(data, forKey: "ActivityProfiles")
        } catch {
            logger.error("Error enconding")
        }

    }
    
}

