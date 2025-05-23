//
//  SettingsManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 10/09/2023.
//

import Foundation
import CloudKit
import os

#if os(watchOS)
import WatchKit
var hapticTypes: [WKHapticType] = [.notification, .directionUp, .directionDown,
    .success, .failure, .retry, .start, .stop, .click]
#endif

#if os(iOS)
import StravaSwift
#endif

class SettingsManager: NSObject, ObservableObject  {
    
    let CK_RECORD_NAME: String = "App_Settings"
    let CK_RECORD_TYPE = "Settings"
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "SettingsManager")
    
    ///Access SettingsManager through SettingsManager.shared
    public static let shared = SettingsManager()
    
    @Published var transmitHR: Bool
    @Published var transmitPowerMeter: Bool
    
    @Published var saveAppleHealth: Bool
       
    /// If auto-pause enabled, pause activity if speed drops below this limit
    @Published var autoPauseSpeed: Double
    
    /// If auto-pause enabled and activity is paused, auto-resume when speed increases above this limit (must be greater than autoPauseSpeed!
    @Published var autoResumeSpeed: Double
    
    /// The minimum length of autoPause in seconds - have to pause for greater than this time to reister as a pause
    @Published var minAutoPauseSeconds: Int
    
    @Published var aveCadenceZeros: Bool
    @Published var avePowerZeros: Bool
    
    /// Whether to include HR in average when paused - true -> yes, false -> no
    @Published var aveHRPaused: Bool
    
#if os(watchOS)
    @Published var hapticType: WKHapticType
#endif
    @Published var maxAlarmRepeatCount: Int

    /// Whether to use 3-second power or instantanteous power for cycle power meter reading
    @Published var use3sCyclePower: Bool
    
    /// The number of seconds to average power over on the cycle power graph
    @Published var cyclePowerGraphSeconds: Int
    
    /// **Strava Integration Settings**
    /// Whether Strava interface is enabled
    @Published var stravaEnabled: Bool = false
    
    /// Strava ClientID for authentication
    @Published var stravaClientId: Int?
    
    /// Strava Client Secret for authentication
    @Published var stravaClientSecret: String = ""
    
    /// Whether to fetch data from Strava if Strava integration is enabled
    @Published var stravaFetch: Bool = true
    
    /// Whether to save data to Strava if Strava integration is enabled
    @Published var stravaSave: Bool = true
    
    /// Whether save Strava data is configured by Activity Profile
    @Published var stravaSaveByProfile: Bool = false
    
    /// If Strava save is global (not by profile) whether to save everything, or optional
    @Published var stravaSaveAll: Bool = false
    
    var userPowerMetrics: UserPowerMetrics
    
    
    override init() {
        
        // First read from user defaults, then attempt cloudkit fetch...
        transmitHR = UserDefaults.standard.bool(forKey: "transmitHR")
        transmitPowerMeter = UserDefaults.standard.bool(forKey: "transmitPowerMeter")
        
        saveAppleHealth = UserDefaults.standard.bool(forKey: "saveAppleHealth")
        
        autoPauseSpeed = UserDefaults.standard.object(forKey: "autoPauseSpeed") != nil ? UserDefaults.standard.double(forKey: "autoPauseSpeed") : 0.2
        autoResumeSpeed = UserDefaults.standard.object(forKey: "autoResumeSpeed") != nil ? UserDefaults.standard.double(forKey: "autoResumeSpeed") : 0.4
        minAutoPauseSeconds = UserDefaults.standard.object(forKey: "minAutoPauseSeconds") != nil ? UserDefaults.standard.integer(forKey: "minAutoPauseSeconds") : 3

        aveCadenceZeros = UserDefaults.standard.bool(forKey: "aveCadenceZeros")
        avePowerZeros = UserDefaults.standard.bool(forKey: "avePowerZeros")
        aveHRPaused = UserDefaults.standard.bool(forKey: "aveHRPaused")
        #if os(watchOS)
        hapticType = WKHapticType(rawValue: UserDefaults.standard.integer(forKey: "hapticType")) ?? .notification
        #endif
        maxAlarmRepeatCount = max( UserDefaults.standard.integer(forKey: "maxAlarmRepeatCount"), 1 )
        
        // default to true if not set
        use3sCyclePower = UserDefaults.standard.object(forKey: "use3sCyclePower") != nil ? UserDefaults.standard.bool(forKey: "use3sCyclePower") : true
        let _cyclePowerGraphSeconds: Int =  UserDefaults.standard.integer(forKey: "cyclePowerGraphSeconds")
        cyclePowerGraphSeconds = _cyclePowerGraphSeconds == 0 ? 30 : _cyclePowerGraphSeconds
        
        stravaEnabled = UserDefaults.standard.bool(forKey: "stravaEnabled")
        stravaClientId = UserDefaults.standard.integer(forKey: "stravaClientId")
        stravaClientSecret = UserDefaults.standard.string(forKey: "stravaClientSecret") ?? ""
        stravaFetch = UserDefaults.standard.bool(forKey: "stravaFetch")
        stravaSave = UserDefaults.standard.bool(forKey: "stravaSave")
        stravaSaveByProfile = UserDefaults.standard.bool(forKey: "stravaSaveByProfile")
        stravaSaveAll = UserDefaults.standard.bool(forKey: "stravaSaveAll")
        
        userPowerMetrics = UserPowerMetrics()
        
        super.init()

        readFromCloudKit()
    }
    
    
    func readFromCloudKit() {
        
        let recordID = CloudKitOperation().getCKRecordID(recordName: CK_RECORD_NAME)
        
        CKFetchRecordOperation(recordID: recordID,
                               completionFunction: fromCKRecord,
                               completionFailureFunction: { }).execute()
        
        
        
    }
    
    
    /// Convert CKRecord to settings
    func fromCKRecord(ckRecord: CKRecord) {
        
        if ckRecord.recordType != CK_RECORD_TYPE {
            logger.error("Incorrect record type for Settings")
            return
        }
        
        DispatchQueue.main.async {
            self.transmitHR = ckRecord["transmitHR"] ?? false as Bool
            self.transmitPowerMeter = ckRecord["transmitPowerMeter"] ?? false as Bool
            self.saveAppleHealth = ckRecord["saveAppleHealth"] ?? false as Bool
            self.autoPauseSpeed = ckRecord["autoPauseSpeed"] ?? 0.2 as Double
            self.autoResumeSpeed = ckRecord["autoResumeSpeed"] ?? 0.4 as Double
            self.minAutoPauseSeconds = ckRecord["minAutoPauseSeconds"] ?? 3 as Int
            self.aveCadenceZeros = ckRecord["aveCadenceZeros"] ?? false as Bool
            self.avePowerZeros = ckRecord["avePowerZeros"] ?? false as Bool
            self.aveHRPaused = ckRecord["aveHRPaused"] ?? false as Bool
    #if os(watchOS)
            self.hapticType = WKHapticType(rawValue: (ckRecord["hapticType"] ?? WKHapticType.notification.rawValue as Int)) ?? WKHapticType.notification
    #endif
            
            self.maxAlarmRepeatCount = ckRecord["maxAlarmRepeatCount"] ?? 1 as Int
            self.use3sCyclePower = ckRecord["use3sCyclePower"] ?? false as Bool
            self.cyclePowerGraphSeconds = ckRecord["cyclePowerGraphSeconds"] ?? 30 as Int
            self.stravaEnabled = ckRecord["stravaEnabled"] ?? false as Bool
            self.stravaClientId = ckRecord["stravaClientId"] as Int?
            self.stravaClientSecret = ckRecord["stravaClientSecret"] ?? "" as String
            self.stravaFetch = ckRecord["stravaFetch"] ?? false as Bool
            self.stravaSave = ckRecord["stravaSave"] ?? false as Bool
            self.stravaSaveByProfile = ckRecord["stravaSaveByProfile"] ?? false as Bool
            self.stravaSaveAll = ckRecord["stravaSaveAll"] ?? false as Bool
            
            self.saveToUserDefaults()
        }
            

    }
    
    /// Save to local user defaults and then save to shared CloudKit
    func save() {

        saveToUserDefaults()
        
        // Save settings data to CloudKit
        saveToCloudKit()

    }
    
    
    
    func saveToUserDefaults() {

        UserDefaults.standard.set(transmitHR, forKey: "transmitHR")
        UserDefaults.standard.set(transmitPowerMeter, forKey: "transmitPowerMeter")
        
        UserDefaults.standard.set(saveAppleHealth, forKey: "saveAppleHealth")
        
        UserDefaults.standard.set(autoPauseSpeed, forKey: "autoPauseSpeed")
        UserDefaults.standard.set(autoResumeSpeed, forKey: "autoResumeSpeed")
        UserDefaults.standard.set(minAutoPauseSeconds, forKey: "minAutoPauseSeconds")

        UserDefaults.standard.set(aveCadenceZeros, forKey: "aveCadenceZeros")
        UserDefaults.standard.set(avePowerZeros, forKey: "avePowerZeros")
        UserDefaults.standard.set(aveHRPaused, forKey: "aveHRPaused")
        #if os(watchOS)
        UserDefaults.standard.set(hapticType.rawValue, forKey: "hapticType")
        #endif
        UserDefaults.standard.set(maxAlarmRepeatCount, forKey: "maxAlarmRepeatCount")

        UserDefaults.standard.set(use3sCyclePower, forKey: "use3sCyclePower")
        UserDefaults.standard.set(cyclePowerGraphSeconds, forKey: "cyclePowerGraphSeconds")

        UserDefaults.standard.set(stravaEnabled, forKey: "stravaEnabled")
        UserDefaults.standard.set(stravaClientId, forKey: "stravaClientId")
        UserDefaults.standard.set(stravaClientSecret, forKey: "stravaClientSecret")
        UserDefaults.standard.set(stravaFetch, forKey: "stravaFetch")
        UserDefaults.standard.set(stravaSave, forKey: "stravaSave")
        UserDefaults.standard.set(stravaSaveByProfile, forKey: "stravaSaveByProfile")
        UserDefaults.standard.set(stravaSaveAll, forKey: "stravaSaveAll")
        
        #if os(iOS)
        if stravaEnabled {
            let config = StravaConfig(
                clientId: stravaClientId ?? 0,        // 138595,
                clientSecret: stravaClientSecret,    //"86ff0c43b3bdaddc87264a2b85937237639a1ac9",
                redirectUri: "aleph://localhost",
                scopes: [.activityReadAll, .activityWrite],
                delegate: PersistentTokenDelegate()
            )
            _ = StravaClient.sharedInstance.initWithConfig(config)
        }
        #endif

    }
    

   
    
    /// Save settings to CloudKit
    func saveToCloudKit() {
        CKForceUpdateOperation(ckRecord: asCKRecord(),
                               completionFunction: {_ in }).execute()
    }
    
    
    /// Convert settings data to CKRecord
    func asCKRecord() -> CKRecord {

//      Create record with fixed recordID for single settings record
        let record = CKRecord(recordType: CK_RECORD_TYPE, recordID: CloudKitOperation().getCKRecordID(recordName: CK_RECORD_NAME))
        
        record["transmitHR"] = transmitHR as CKRecordValue
        record["transmitPowerMeter"] = transmitPowerMeter as CKRecordValue
        record["saveAppleHealth"] = saveAppleHealth as CKRecordValue
        record["autoPauseSpeed"] = autoPauseSpeed as CKRecordValue
        record["autoResumeSpeed"] = autoResumeSpeed as CKRecordValue
        record["minAutoPauseSeconds"] = minAutoPauseSeconds as CKRecordValue
        record["aveCadenceZeros"] = aveCadenceZeros as CKRecordValue
        record["avePowerZeros"] = avePowerZeros as CKRecordValue
        record["aveHRPaused"] = aveHRPaused as CKRecordValue
#if os(watchOS)
        record["hapticType"] = hapticType.rawValue as CKRecordValue
#endif
        
        record["maxAlarmRepeatCount"] = maxAlarmRepeatCount as CKRecordValue
        record["use3sCyclePower"] = use3sCyclePower as CKRecordValue
        record["cyclePowerGraphSeconds"] = cyclePowerGraphSeconds as CKRecordValue
        record["stravaEnabled"] = stravaEnabled as CKRecordValue
        record["stravaClientId"] = stravaClientId as CKRecordValue?
        record["stravaClientSecret"] = stravaClientSecret as CKRecordValue
        record["stravaFetch"] = stravaFetch as CKRecordValue
        record["stravaSave"] = stravaSave as CKRecordValue
        record["stravaSaveByProfile"] = stravaSaveByProfile as CKRecordValue
        record["stravaSaveAll"] = stravaSaveAll as CKRecordValue
        
        return record
    }
   
    
    func registerNotifications(notificationManager: CloudKitNotificationManager) {
        notificationManager.registerNotificationFunctions(recordType: CK_RECORD_TYPE,
                                                          recordDeletionFunction: { _ in },                         // record should not get deleted!!
                                                          recordChangeFunction: { _ in self.readFromCloudKit() })   // only a single record!
    }
    
    func fetchFromStrava() -> Bool {
        return (stravaEnabled && stravaFetch)
    }
    
    func offerSaveToStrava() -> Bool {
        return (stravaEnabled && stravaSave)
    }
    
    func offerSaveByProfile() -> Bool {
        return (offerSaveToStrava() && stravaSaveByProfile)
    }
}

#if os(watchOS)
extension WKHapticType: @retroactive Identifiable {
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
#endif
