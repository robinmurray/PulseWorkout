//
//  UserProfile.swift
//  PulseWorkout
//
//  Created by Robin Murray on 29/11/2025.
//

import Foundation
import os

struct UserProfileRecord {
    var element: String
    var validFrom: Date
    var singleValue: Double
    var listValue: [Double]
}

class UserProfile: NSObject, ObservableObject  {
        
    ///Access UserProfile through UserProfile.shared
    public static let shared = SettingsManager()
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "UserProfile")
    

    /// Return user profile FTP at the given date
    func FTP(at: Date) -> Int? {
        
        return 275
    }
    
    
    /// Return power zone limits at the given date
    func powerZoneLimits(at: Date) -> [Int] {
        
        let defaultPowerZoneRatios = [0, 0.55, 0.75, 0.9, 1.05, 1.2]
        guard let FTPforCalc = FTP(at: at) else {return []}

        return defaultPowerZoneRatios.map({ Int(round($0 * Double(FTPforCalc))) })
    }
    

    /// Return threshold heart rate at the give date
    func thresholdHR(at: Date) -> Int? {
        
        return 154
    }
    

    /// Return maximum heart rate at the give date
    func maxHR(at: Date) -> Int? {
        
        return 164
    }
    

    /// Return resting heart rate at the given date
    func restHR(at: Date) -> Int? {
        
        return 52
    }

    
    /// Return heart rate zone limits at the given date
    func HRZoneLimits(at: Date) -> [Int] {

        let HRZoneRatios = [0, 0.68, 0.83, 0.93, 1.00]
        guard let currentThesholdHR = thresholdHR(at: at) else {return []}
        
        return HRZoneRatios.map({ Int(round($0 * Double(currentThesholdHR))) })
        
    }
    
    
    /// Return weight in KG at the given date
    func weightKG() -> Double? {
        
        return 69
    }

}
