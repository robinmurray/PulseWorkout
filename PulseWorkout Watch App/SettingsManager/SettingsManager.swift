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
    
    @Published var saveAppleHealth: Bool
    @Published var saveStrava: Bool
    
    @Published var autoPause: Bool
    @Published var aveCadenceZeros: Bool
    @Published var avePowerZeros: Bool
    

    override init() {
        
        transmitHR = UserDefaults.standard.bool(forKey: "transmitHR")
        transmitPowerMeter = UserDefaults.standard.bool(forKey: "transmitPowerMeter")
        
        saveAppleHealth = UserDefaults.standard.bool(forKey: "saveAppleHealth")
        saveStrava = UserDefaults.standard.bool(forKey: "saveStrava")
        
        autoPause = UserDefaults.standard.bool(forKey: "autoPause")
        aveCadenceZeros = UserDefaults.standard.bool(forKey: "aveCadenceZeros")
        avePowerZeros = UserDefaults.standard.bool(forKey: "avePowerZeros")

        super.init()

    }
    
    func save() {

        UserDefaults.standard.set(transmitHR, forKey: "transmitHR")
        UserDefaults.standard.set(transmitPowerMeter, forKey: "transmitPowerMeter")
        
        UserDefaults.standard.set(saveAppleHealth, forKey: "saveAppleHealth")
        UserDefaults.standard.set(saveStrava, forKey: "saveStrava")
        
        UserDefaults.standard.set(autoPause, forKey: "autoPause")
        UserDefaults.standard.set(aveCadenceZeros, forKey: "aveCadenceZeros")
        UserDefaults.standard.set(avePowerZeros, forKey: "avePowerZeros")

    }
    
}
