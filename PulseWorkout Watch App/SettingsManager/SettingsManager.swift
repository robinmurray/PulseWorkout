//
//  SettingsManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 10/09/2023.
//

import Foundation
import WatchKit

var hapticTypes: [WKHapticType] = [.notification, .directionUp, .directionDown,
    .success, .failure, .retry, .start, .stop, .click]

class SettingsManager: NSObject, ObservableObject  {
    
    @Published var transmitHR: Bool
    @Published var transmitPowerMeter: Bool
    
    @Published var saveAppleHealth: Bool
    @Published var saveStrava: Bool
    
    @Published var autoPause: Bool
    @Published var aveCadenceZeros: Bool
    @Published var avePowerZeros: Bool
    @Published var hapticType: WKHapticType
    @Published var maxAlarmRepeatCount: Int

    override init() {
        
        transmitHR = UserDefaults.standard.bool(forKey: "transmitHR")
        transmitPowerMeter = UserDefaults.standard.bool(forKey: "transmitPowerMeter")
        
        saveAppleHealth = UserDefaults.standard.bool(forKey: "saveAppleHealth")
        saveStrava = UserDefaults.standard.bool(forKey: "saveStrava")
        
        autoPause = UserDefaults.standard.bool(forKey: "autoPause")
        aveCadenceZeros = UserDefaults.standard.bool(forKey: "aveCadenceZeros")
        avePowerZeros = UserDefaults.standard.bool(forKey: "avePowerZeros")
        hapticType = WKHapticType(rawValue: UserDefaults.standard.integer(forKey: "hapticType")) ?? .notification
        maxAlarmRepeatCount = max( UserDefaults.standard.integer(forKey: "maxAlarmRepeatCount"), 1 )
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
        UserDefaults.standard.set(hapticType.rawValue, forKey: "hapticType")
        UserDefaults.standard.set(maxAlarmRepeatCount, forKey: "maxAlarmRepeatCount")

    }
    
}


extension WKHapticType: Identifiable {
    public var id: Int {
        rawValue
    }
    
    var name: String {
        switch self {
        case .notification:
            return "notification"
        case .directionUp:
            return "directionUp"
        case .directionDown:
            return "directionDown"
        case .success:
            return "success"
        case .failure:
            return "failure"
        case .retry:
            return "retry"
        case .start:
            return "start"
        case .stop:
            return "stop"
        case .click:
            return "click"
        case .navigationGenericManeuver:
            return "navigationGenericManeuver"
        case .navigationLeftTurn:
            return "navigationLeftTurn"
        case .navigationRightTurn:
            return "navigationRightTurn"
        case .underwaterDepthCriticalPrompt:
            return "underwaterDepthCriticalPrompt"
        case .underwaterDepthPrompt:
            return "underwaterDepthPrompt"
        default:
            return ""
        }
    }
}
