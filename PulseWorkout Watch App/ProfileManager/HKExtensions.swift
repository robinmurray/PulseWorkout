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
    
    var iconImage: String {
        switch self {
        case .crossTraining:
            return "figure.cross.training"
        case .cycling:
            return "figure.outdoor.cycle"
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
