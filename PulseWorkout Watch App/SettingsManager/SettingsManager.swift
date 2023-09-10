//
//  SettingsManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 10/09/2023.
//

import Foundation


class SettingsManager: NSObject, ObservableObject  {
    
    @Published var transmitHR: Bool
    @Published var transmitPowerMeter: Bool
    
    override init() {
        
        transmitHR = UserDefaults.standard.bool(forKey: "transmitHR")
        transmitPowerMeter = UserDefaults.standard.bool(forKey: "transmitPowerMeter")

        super.init()

    }
    
    func save() {

        UserDefaults.standard.set(transmitHR, forKey: "transmitHR")
        UserDefaults.standard.set(transmitPowerMeter, forKey: "transmitPowerMeter")

    }
    
}
