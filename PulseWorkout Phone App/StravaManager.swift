//
//  StravaManager.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 22/01/2025.
//

import Foundation
import StravaSwift
import os


typealias StravaActivity = Activity

/** The default token delegate. You should replace this with something that persists the token (e.g. to NSUserDefaults)
**/
class PersistentTokenDelegate: TokenDelegate {
   fileprivate var token: OAuthToken?

//    public let accessToken: String?
//    public let refreshToken: String?
//    public let expiresAt : Int?
    
    let tokenKey: String = "StravaOAUTHToken"
   /**
    Retrieves the token

    - Returns: a optional OAuthToken
    **/
   open func get() -> OAuthToken? {
       let tokenDict:[String:Any?] =  UserDefaults.standard.dictionary(forKey: tokenKey) ?? [:]

       guard let accessToken = tokenDict["accessToken"] as? String?,
             let refreshToken = tokenDict["refreshToken"] as? String?,
             let expiresAt = tokenDict["expiresAt"] as? Int? else {return nil}

       self.token = OAuthToken(access: accessToken, refresh: refreshToken, expiry: expiresAt)
       return token
   }

   /**
    Stores the token internally (note that it is not persisted between app start ups)

    - Parameter token: an optional OAuthToken
    **/
   open func set(_ token: OAuthToken?) {
       let tokenDict:[String:Any?] = ["accessToken" : token?.accessToken as Any?,
                                    "refreshToken": token?.refreshToken as Any?,
                                    "expiresAt" : token?.expiresAt as Any?]

       UserDefaults.standard.set(tokenDict, forKey: tokenKey)
       self.token = token
   }
}



class StravaOperation: NSObject, ObservableObject {
    
    @Published var stravaBusy: Bool
    var forceReauth: Bool
    var forceRefresh: Bool
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "stravaOperation")
    
    init(forceReauth: Bool = false, forceRefresh: Bool = false) {
        self.forceReauth = forceReauth
        self.forceRefresh = forceRefresh
        self.stravaBusy = false
    }
 
    func stravaBusyStatus(_ busy: Bool) {
        DispatchQueue.main.async {
            self.stravaBusy = busy
        }
    }
    
    func authenticate(completionHandler: @escaping () -> Void, failureCompletionHandler: @escaping () -> Void) {
        self.stravaBusyStatus(true)

        StravaClient.sharedInstance.authorize() { [weak self] (result: Result<OAuthToken, Error>) in

            guard let self = self else { return }

            self.didAuthenticate(result: result, completionHandler: completionHandler, failureCompletionHandler: failureCompletionHandler)
            
        }
    }
    
    func refreshToken(completionHandler: @escaping () -> Void, failureCompletionHandler: @escaping () -> Void) {
        
        StravaClient.sharedInstance.refreshAccessToken(StravaClient.sharedInstance.token!.refreshToken!) { [weak self] (result: Result<OAuthToken, Error>) in
            guard let self = self else { return }
            self.didAuthenticate(result: result, completionHandler: completionHandler, failureCompletionHandler: failureCompletionHandler)

        }
    }

    
    private func didAuthenticate(result: Result<OAuthToken, Error>, completionHandler: @escaping () -> Void, failureCompletionHandler: @escaping () -> Void) {
        
        self.stravaBusyStatus(false)
        
        switch result {
            case .success(let token):
//                self.token = token
                self.logger.info("Authentication Success! token : \(token)")
                let expirySeconds = token.expiresAt ?? 0
                let expiryDate = Date(timeIntervalSince1970: TimeInterval(expirySeconds))
                self.logger.info("Token expiry : \(expiryDate)")
                completionHandler()
            
            case .failure(let error):
                self.logger.error("Authentication Error \(error)")
                failureCompletionHandler()
        }
    }
    
    func validToken(execFunction: @escaping () -> Void, failureCompletionHandler: @escaping () -> Void) -> Bool {
        
        if let authToken = StravaClient.sharedInstance.token {
            if (authToken.expiresAt ?? 0) < Int(Date().timeIntervalSince1970) {
                logger.info("Refresh Token")
                refreshToken(completionHandler: execFunction, failureCompletionHandler: failureCompletionHandler)
                return false
            }
        } else {
            authenticate(completionHandler: execFunction, failureCompletionHandler: failureCompletionHandler)
            return false
        }
        
        if forceReauth {
            forceReauth = false
            authenticate(completionHandler: execFunction, failureCompletionHandler: failureCompletionHandler)
            return false
        }

        if forceRefresh {
            forceRefresh = false
            refreshToken(completionHandler: execFunction, failureCompletionHandler: failureCompletionHandler)
            return false
        }
        return true
    }

    
    
}

class StravaFetchActivities: StravaOperation {

    var params: [String:String] = [:]
    var completionHandler: ([StravaActivity]) -> Void
    var failureCompletionHandler: () -> Void
    
    
    init(page: Int = 1,
         perPage: Int = 30,
         before: Date? = nil,
         after: Date? = nil,
         completionHandler: @escaping ([StravaActivity]) -> Void,
         failureCompletionHandler: @escaping () -> Void = { },
         forceReauth: Bool = false,
         forceRefresh: Bool = false) {
        
        params["page"] = String(page)
        params["per_page"] = String(perPage)

        if let beforeDate = before {
            let beforeSecs = Int(beforeDate.timeIntervalSince1970)
            params["before"] = String(beforeSecs)
        }

        if let afterDate = after {
            let afterSecs = Int(afterDate.timeIntervalSince1970)
            params["after"] = String(afterSecs)
        }

        self.completionHandler = completionHandler
        self.failureCompletionHandler = failureCompletionHandler
        
        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)

    }


    
    func execute() {
    
        if validToken(execFunction: self.execute, failureCompletionHandler: failureCompletionHandler) {

            StravaClient.sharedInstance.request(Router.athleteActivities(params: params), result: { [weak self] (activities: [StravaActivity]?) in
                guard let self = self else { return }
                self.stravaBusyStatus(false)

                guard let activities = activities else { return }

                self.completionHandler(activities)

            }, failure: { (error: NSError) in
                self.stravaBusyStatus(false)
                self.logger.error("Error : \(error.localizedDescription)")
                
                // Call passed failure handler, if present
                self.failureCompletionHandler()
            })
        }

    }
    
    class func dummyCompletion( fetchedActivities: [StravaActivity]) {
        
        let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                            category: "stravaOperation")
        
        var activities: [StravaActivity] = []
        activities = fetchedActivities
        
        logger.info("Fetched Count = \(activities.count)")
        logger.info("Strava activities : \(activities)")
        
    }
}


class StravaFetchLatestActivities: StravaOperation {
    
    var page: Int = 1
    var perPage: Int
    var after: Date
    var activityIndex: Int = 0
    var stravaActivityPage: [StravaActivity] = []
    var dataCache: DataCache
    var thisFetchDate: Int
    var completionHandler: () -> Void
    var failureCompletionHandler: () -> Void
    
    init(perPage: Int = 30,
         after: Date? = nil,
         forceReauth: Bool = false,
         forceRefresh: Bool = false,
         dataCache: DataCache,
         completionHandler: @escaping () -> Void,
         failureCompletionHandler: @escaping () -> Void = { }) {
        
        self.perPage = perPage
        
        thisFetchDate = Int(Date().timeIntervalSince1970)
        let lastFetchDate = UserDefaults.standard.integer(forKey: "stravaFetchDate")
        

        
        if let fixedAfter = after {
            self.after = fixedAfter
        }
        else if lastFetchDate != 0 {
            self.after = Date(timeIntervalSince1970: TimeInterval(lastFetchDate))
        } else {
            // If no date set then will set to now and not fetch anything!
            self.after = Date()
        }

        self.dataCache = dataCache
        self.completionHandler = completionHandler
        self.failureCompletionHandler = failureCompletionHandler
        
        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)

    }
    
    func execute() {
        getNextPage()
    }
    
    func getNextPage() {
        
        StravaFetchActivities(page: page,
                              perPage: perPage,
                              before: nil,
                              after: after,
                              completionHandler: self.gotPage,
                              failureCompletionHandler: self.failureCompletionHandler,
                              forceReauth: forceReauth,
                              forceRefresh: forceRefresh).execute()
    }
    
    func gotPage(stravaActivities: [StravaActivity]) {
        
        self.stravaActivityPage = stravaActivities
        
        if stravaActivities.count == 0 {
            // has fetched last page!
            logger.info("Multi-page fetch completed")

            UserDefaults.standard.set(thisFetchDate, forKey: "stravaFetchDate")

            completionHandler()
            
        }
        else {
            page += 1
            activityIndex = 0
            processNextRecord()
        }
        
    }
    
    func processNextRecord() {
        
        if activityIndex >= self.stravaActivityPage.count {
            // Have finished processing this page
            getNextPage()
        }
        else {
            StravaFetchFullActivity(stravaActivityId: self.stravaActivityPage[activityIndex].id!,
                                    completionHandler: {
                activityRecord in
                
                    activityRecord.save(dataCache: self.dataCache)
                
                    self.dataCache.saveAndDeleteRecord(recordsToSave: [activityRecord.asCKRecord()],
                                                       recordIDsToDelete: [],
                                                       recordSaveSuccessCompletionFunction: {_ in
                        self.activityIndex += 1
                        self.processNextRecord()
                    },
                                                       recordDeleteSuccessCompletionFunction: {_ in })
                
                },
                                    failureCompletionHandler: self.failureCompletionHandler
            ).execute()
        }

    }
    
}

class StravaFetchActivity: StravaOperation {

    var stravaActivityId: Int
    var completionHandler: (StravaActivity) -> Void
    var failureCompletionHandler: () -> Void
    
    
    init(stravaActivityId: Int,
         completionHandler: @escaping (StravaActivity) -> Void,
         failureCompletionHandler: @escaping () -> Void = { },
         forceReauth: Bool = false,
         forceRefresh: Bool = false) {
        
        self.stravaActivityId = stravaActivityId
        self.completionHandler = completionHandler
        self.failureCompletionHandler = failureCompletionHandler
        
        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)

    }


    
    func execute() {
    
        if validToken(execFunction: self.execute, failureCompletionHandler: failureCompletionHandler) {

            StravaClient.sharedInstance.request(Router.activities(id: stravaActivityId, params: nil), result: { [weak self] (activity: StravaActivity?) in
                guard let self = self else { return }
                self.stravaBusyStatus(false)

                guard let activity = activity else { return }

                self.completionHandler(activity)

            }, failure: { (error: NSError) in
                self.stravaBusyStatus(false)
                self.logger.error("Error : \(error.localizedDescription)")
                self.failureCompletionHandler()
            })
        }

    }
    
    class func dummyCompletion(fetchedActivity: StravaActivity) {
        
        let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                            category: "stravaOperation")
    
        logger.info("Strava activity : \(fetchedActivity)")
        
    }
}


class StravaFetchActivityStreams: StravaOperation {

    var stravaActivityId: Int
    var streams: [String]
    var completionHandler: ([StravaSwift.Stream]) -> Void
    var failureCompletionHandler: () -> Void
    
    
    init(stravaActivityId: Int,
         streams: [String],
         completionHandler: @escaping ([StravaSwift.Stream]) -> Void,
         failureCompletionHandler: @escaping () -> Void = { },
         forceReauth: Bool = false,
         forceRefresh: Bool = false) {
        
        self.stravaActivityId = stravaActivityId
        self.streams = streams
        self.completionHandler = completionHandler
        self.failureCompletionHandler = failureCompletionHandler
        
        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)

    }


    
    func execute() {
    
        if validToken(execFunction: self.execute, failureCompletionHandler: failureCompletionHandler) {

            let streamParam = streams.joined(separator: ",")
            StravaClient.sharedInstance.request(Router.activityStreams(id: stravaActivityId, types: streamParam), result: { [weak self] (streams: [StravaSwift.Stream]?) in
                guard let self = self else { return }
                self.stravaBusyStatus(false)

                guard let streams = streams else { return }

                self.completionHandler(streams)

            }, failure: { (error: NSError) in
                self.stravaBusyStatus(false)
                self.logger.error("Error : \(error.localizedDescription)")
                self.failureCompletionHandler()
            })
        }

    }
    
    class func dummyCompletion(streams: [StravaSwift.Stream]) {
        
        let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                            category: "stravaOperation")
    
        logger.info("Strava streams : \(streams)")
        
    }
}


class StravaFetchFullActivity: StravaOperation {

    var stravaActivityId: Int
    var completionHandler: (ActivityRecord) -> Void
    var fetchedStravaActivity: StravaActivity?
    var failureCompletionHandler: () -> Void
    
    
    init(stravaActivityId: Int,
         completionHandler: @escaping (ActivityRecord) -> Void,
         failureCompletionHandler: @escaping () -> Void = { },
         forceReauth: Bool = false,
         forceRefresh: Bool = false) {
        
        self.stravaActivityId = stravaActivityId
        self.completionHandler = completionHandler
        self.failureCompletionHandler = failureCompletionHandler
        
        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)

    }


    
    func execute() {
    
        StravaFetchActivity(stravaActivityId: stravaActivityId,
                            completionHandler: self.onFetchActivity,
                            failureCompletionHandler: self.failureCompletionHandler).execute()

    }
    
    func onFetchActivity(stravaActivity: StravaActivity) {
        
        fetchedStravaActivity = stravaActivity
        
        StravaFetchActivityStreams(stravaActivityId: stravaActivityId,
                                   streams: ["time", "distance", "latlng", "heartrate", "altitude", "cadence", "watts", "velocity_smooth"],
                                   completionHandler: self.onFetchActivityStreams,
                                   failureCompletionHandler: failureCompletionHandler).execute()
        
    }
    
    func onFetchActivityStreams(streams: [StravaSwift.Stream]) {
        
        let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                            category: "stravaOperation")
        
        logger.info("Strava streams : \(streams)")
        
        if let stravaActivity = fetchedStravaActivity {
            let activityRecord = ActivityRecord(fromStravaActivity: stravaActivity,
                                                settingsManager: SettingsManager())
            
            // Add Streams
            activityRecord.addStreams(streams)
            
            // Call original completion handler
            self.completionHandler(activityRecord)
        }
        
    }
    
    class func dummyCompletion(activityRecord: ActivityRecord) {
        
        let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                            category: "stravaOperation")
    
        logger.info("Activity Record : \(activityRecord)")
        
    }
}


