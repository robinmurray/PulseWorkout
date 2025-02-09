//
//  HKExtensions.swift
//  PulseWorkout
//
//  Created by Robin Murray on 19/11/2024.
//

import Foundation
import HealthKit



extension HKWorkoutActivityType: @retroactive Identifiable {
    public var id: UInt {
        rawValue
    }
    
    var name: String {
        switch self {
        case .crossTraining:
            return "Cross Training"
        case .cycling:
            return "Cycling"
        case .flexibility:
            return "Flexibility"
        case .functionalStrengthTraining:
            return "Strength Training"
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
            return "Workout"
        }
    }
    
    var iconImage: String {
        switch self {
        case .crossTraining:
            return "figure.cross.training"
        case .cycling:
            return "figure.outdoor.cycle"
        case .flexibility:
            return "figure.yoga"
        case .functionalStrengthTraining:
            return "figure.strengthtraining.traditional"
        case .mixedCardio:
            return "figure.run.square.stack"
        case .paddleSports:
            return "oar.2.crossed"
        case .rowing:
            return "oar.2.crossed"
        case .running:
            return "figure.run"
        case .walking:
            return "figure.walk"
        default:
            return "figure.run"
        }
    }
    
    var stravaTypes: [String] {
        switch self {
        case .crossTraining:
            return ["Crossfit", "HighIntensityIntervalTraining", "Workout"]
        case .cycling:
            return ["EBikeRide", "EMountainBikeRide", "GravelRide", "Handcycle", "MountainBikeRide", "Ride", "Velomobile", "VirtualRide"]
        case .flexibility:
            return ["Pilates", "Yoga"]
        case .functionalStrengthTraining:
            return ["WeightTraining"]
        case .mixedCardio:
            return ["Crossfit", "HighIntensityIntervalTraining", "Workout"]
        case .paddleSports:
            return ["Canoeing", "Kayaking", "StandUpPaddling"]
        case .rowing:
            return ["Rowing", "VirtualRow"]
        case .running:
            return ["Run", "TrailRun", "VirtualRun"]
        case .walking:
            return ["Hike", "Walk"]
        default: // Unmapped Strava Types...
            return ["AlpineSki", "BackcountrySki", "Badminton", "Elliptical", "Golf", "IceSkate", "InlineSkate", "Kitesurf", "NordicSki", "Pickleball", "Racquetball", "RockClimbing", "RollerSki", "Sail", "Skateboard", "Snowboard", "Snowshoe", "Soccer", "Squash", "StairStepper", "Surfing", "Swim", "TableTennis", "Tennis", "Wheelchair", "Windsurf", "Workout"]
        }
    }
    
    var defaultStravaType: String {
        switch self {
        case .crossTraining:
            return "Crossfit"
        case .cycling:
            return "Ride"
        case .flexibility:
            return "Pilates"
        case .functionalStrengthTraining:
            return "WeightTraining"
        case .mixedCardio:
            return "Crossfit"
        case .paddleSports:
            return "Kayaking"
        case .rowing:
            return "Rowing"
        case .running:
            return "Run"
        case .walking:
            return "Walk"
        default: // Unmapped Strava Types...
            return "Workout"
        }
    }
}


func getHKWorkoutActivityType(_ stravaActivityType: String) -> HKWorkoutActivityType {
    
    switch stravaActivityType {
    case "AlpineSki":
        return HKWorkoutActivityType.snowSports
    case "BackcountrySki":
        return HKWorkoutActivityType.snowSports
    case "Canoeing":
        return HKWorkoutActivityType.paddleSports
    case "Crossfit":
        return HKWorkoutActivityType.crossTraining
    case "EBikeRide":
        return HKWorkoutActivityType.cycling
    case "Elliptical":
        return HKWorkoutActivityType.crossTraining
    case "Golf":
        return HKWorkoutActivityType.golf
    case "Handcycle":
        return HKWorkoutActivityType.handCycling
    case "Hike":
        return HKWorkoutActivityType.walking
    case "IceSkate":
        return HKWorkoutActivityType.skatingSports
    case "InlineSkate":
        return HKWorkoutActivityType.skatingSports
    case "Kayaking":
        return HKWorkoutActivityType.paddleSports
    case "Kitesurf":
        return HKWorkoutActivityType.surfingSports
    case "NordicSki":
        return HKWorkoutActivityType.crossCountrySkiing
    case "Ride":
        return HKWorkoutActivityType.cycling
    case "RockClimbing":
        return HKWorkoutActivityType.climbing
    case "RollerSki":
        return HKWorkoutActivityType.crossCountrySkiing
    case "Rowing":
        return HKWorkoutActivityType.rowing
    case "Run":
        return HKWorkoutActivityType.running
    case "Sail":
        return HKWorkoutActivityType.sailing
    case "Skateboard":
        return HKWorkoutActivityType.skatingSports
    case "Snowboard":
        return HKWorkoutActivityType.snowboarding
    case "Snowshoe":
        return HKWorkoutActivityType.snowSports
    case "Soccer":
        return HKWorkoutActivityType.soccer
    case "StairStepper":
        return HKWorkoutActivityType.crossTraining
    case "StandUpPaddling":
        return HKWorkoutActivityType.paddleSports
    case "Surfing":
        return HKWorkoutActivityType.surfingSports
    case "Swim":
        return HKWorkoutActivityType.swimming
    case "Velomobile":
        return HKWorkoutActivityType.cycling
    case "VirtualRide":
        return HKWorkoutActivityType.cycling
    case "VirtualRun":
        return HKWorkoutActivityType.running
    case "Walk":
        return HKWorkoutActivityType.walking
    case "WeightTraining":
        return HKWorkoutActivityType.functionalStrengthTraining
    case "Wheelchair":
        return HKWorkoutActivityType.wheelchairWalkPace
    case "Windsurf":
        return HKWorkoutActivityType.surfingSports
    case "Workout":
        return HKWorkoutActivityType.crossTraining
    case "Yoga":
        return HKWorkoutActivityType.yoga
    default:
        return HKWorkoutActivityType.running
    }
    

}


func getHKWorkoutSessionLocationType(_ stravaActivityType: String) -> HKWorkoutSessionLocationType {
    
    switch stravaActivityType {
        
    case "Crossfit", "Elliptical", "IceSkate", "StairStepper", "VirtualRide", "VirtualRun", "WeightTraining", "Yoga":
        return HKWorkoutSessionLocationType.indoor
    default:
        return HKWorkoutSessionLocationType.outdoor

    }
}


extension HKWorkoutSessionLocationType: @retroactive Identifiable {
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
