//
//  ActivityProfile.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 19/02/2023.
//

import Foundation
import HealthKit


struct ActivityProfile: Codable, Identifiable {
    var name: String
    var workoutTypeId: UInt
    var workoutLocationId: Int
    var hiLimitAlarmActive: Bool
    var hiLimitAlarm: Int
    var loLimitAlarmActive: Bool
    var loLimitAlarm: Int
    var playSound: Bool
    var playHaptic: Bool
    var constantRepeat: Bool
    var lockScreen: Bool
    var id: UUID?
    var lastUsed: Date?
    
}

//@Published var workoutType: HKWorkoutActivityType = HKWorkoutActivityType.cycling
//@Published var workoutLocation: HKWorkoutSessionLocationType = HKWorkoutSessionLocationType.outdoor

class ActivityProfiles: NSObject {

    var profiles: [ActivityProfile] = []
    
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
    
    func addNew() {
        add(activityProfile: ActivityProfile ( name: "New",
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

    func UIProfileList() -> [ActivityProfile] {
        
        let  newActivityProfile = ActivityProfile ( name: "New Profile",
                                                       workoutTypeId: HKWorkoutActivityType.cycling.rawValue,
                                                       workoutLocationId: HKWorkoutSessionLocationType.outdoor.rawValue,
                                                       hiLimitAlarmActive: false,
                                                       hiLimitAlarm: 140,
                                                       loLimitAlarmActive: false,
                                                       loLimitAlarm: 100,
                                                       playSound: false,
                                                       playHaptic: false,
                                                       constantRepeat: false,
                                                       lockScreen: false)

        let epochDate = NSDate(timeIntervalSince1970: 0) as Date
        var profileList = profiles.sorted(by: { $0.lastUsed ?? epochDate > $1.lastUsed ?? epochDate })
        profileList.append(newActivityProfile)
        return profileList
        
    }
    
    func getDefault() -> ActivityProfile {
        return ActivityProfile ( name: "Default",
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
                                 id: UUID())
    }
    
    func addDefaults() {
        // Add a set of deault profiles to get application stared.
        
        add(activityProfile: ActivityProfile ( name: "Race",
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

        add(activityProfile: ActivityProfile ( name: "Aerobic",
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

        add(activityProfile: ActivityProfile ( name: "Recovery",
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

    func add(activityProfile: ActivityProfile) {
        /* Add an activity profile to the list of profiles and
         write profiles back to userDefaults */
        
        var newActivityProfile = activityProfile
        if newActivityProfile.id == nil {
            newActivityProfile.id = UUID()
        }
        newActivityProfile.lastUsed = Date()
        
        profiles.append(newActivityProfile)
        self.write()
    }
    
    func remove(activityProfile: ActivityProfile) {
        /* delete an activity profile from profiles and
         write profiles back to userDefaults */
        
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

    func updateOrAdd(activityProfile: ActivityProfile) {
        /* Update activity profile and write to userDefaults.
           If activityProfile has no id then is a new profile - add it... */

        if activityProfile.id == nil {
            add(activityProfile: activityProfile)
        } else {
            update(activityProfile: activityProfile)
        }
        
    }

    
    func update(activityProfile: ActivityProfile) {
        /* Update activity profile and write to userDefaults */

        var updatedActivityProfile = activityProfile

        updatedActivityProfile.lastUsed = Date()

        for (index, profile) in profiles.enumerated() {
            if profile.id == updatedActivityProfile.id {
                profiles[index] = updatedActivityProfile
                
                self.write()
                return
            }
        }
    }

    
    func get(id: UUID) -> ActivityProfile? {
        // return activity profile for a profile id

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
            print("1111111")
            let decoder = JSONDecoder()
            if let loadedProfiles = try? decoder.decode(type(of: profiles), from: savedProfiles) {
                print(loadedProfiles)
                profiles = loadedProfiles
            }
        }
    }

    
    
    func write() {
        
        print("Writing profile!")
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
