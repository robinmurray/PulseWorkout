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
       
    /// If auto-pause enabled, pause activity if speed drops below this limit
    @Published var autoPauseSpeed: Double
    
    /// If auto-pause enabled and activity is paused, auto-resume when speed increases above this limit (must be greater than autoPauseSpeed!
    @Published var autoResumeSpeed: Double
    
    /// The minimum length of autoPause in seconds - have to pause for greater than this time to reister as a pause
    @Published var minAutoPauseSeconds: Int
    
    @Published var aveCadenceZeros: Bool
    @Published var avePowerZeros: Bool
    
    // whether to include HR in average when pasued - true -> yes, false -> no
    @Published var aveHRPaused: Bool
    @Published var hapticType: WKHapticType
    @Published var maxAlarmRepeatCount: Int

    override init() {
        
        transmitHR = UserDefaults.standard.bool(forKey: "transmitHR")
        transmitPowerMeter = UserDefaults.standard.bool(forKey: "transmitPowerMeter")
        
        saveAppleHealth = UserDefaults.standard.bool(forKey: "saveAppleHealth")
        saveStrava = UserDefaults.standard.bool(forKey: "saveStrava")
        
        autoPauseSpeed = UserDefaults.standard.object(forKey: "autoPauseSpeed") != nil ? UserDefaults.standard.double(forKey: "autoPauseSpeed") : 0.2
        autoResumeSpeed = UserDefaults.standard.object(forKey: "autoResumeSpeed") != nil ? UserDefaults.standard.double(forKey: "autoResumeSpeed") : 0.4
        minAutoPauseSeconds = UserDefaults.standard.object(forKey: "minAutoPauseSeconds") != nil ? UserDefaults.standard.integer(forKey: "minAutoPauseSeconds") : 3

        aveCadenceZeros = UserDefaults.standard.bool(forKey: "aveCadenceZeros")
        avePowerZeros = UserDefaults.standard.bool(forKey: "avePowerZeros")
        aveHRPaused = UserDefaults.standard.bool(forKey: "aveHRPaused")
        hapticType = WKHapticType(rawValue: UserDefaults.standard.integer(forKey: "hapticType")) ?? .notification
        maxAlarmRepeatCount = max( UserDefaults.standard.integer(forKey: "maxAlarmRepeatCount"), 1 )
        super.init()

    }
    
    func save() {

        UserDefaults.standard.set(transmitHR, forKey: "transmitHR")
        UserDefaults.standard.set(transmitPowerMeter, forKey: "transmitPowerMeter")
        
        UserDefaults.standard.set(saveAppleHealth, forKey: "saveAppleHealth")
        UserDefaults.standard.set(saveStrava, forKey: "saveStrava")
        
        UserDefaults.standard.set(autoPauseSpeed, forKey: "autoPauseSpeed")
        UserDefaults.standard.set(autoResumeSpeed, forKey: "autoResumeSpeed")
        UserDefaults.standard.set(minAutoPauseSeconds, forKey: "minAutoPauseSeconds")

        UserDefaults.standard.set(aveCadenceZeros, forKey: "aveCadenceZeros")
        UserDefaults.standard.set(avePowerZeros, forKey: "avePowerZeros")
        UserDefaults.standard.set(aveHRPaused, forKey: "aveHRPaused")
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
