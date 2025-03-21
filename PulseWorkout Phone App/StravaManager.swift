//
//  StravaManager.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 22/01/2025.
//

import Foundation
import StravaSwift
import os
import SwiftyJSON

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
                self.logger.error("Error : \(error.localizedDescription) :: \(error)")
                if error.code == 429 {
                    self.logger.error("Strava API limit exceeded")
                }
                
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
    var thisFetchDate: Int
    var completionHandler: () -> Void
    var failureCompletionHandler: () -> Void
    
    init(perPage: Int = 30,
         after: Date? = nil,
         forceReauth: Bool = false,
         forceRefresh: Bool = false,
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
            let stravaId = self.stravaActivityPage[activityIndex].id!
            self.logger.info("processing stravaID \(stravaId)")
            CKQueryForStravaId(stravaId: stravaId,
                               completionFunction: {
                ckRecords in
                    if ckRecords.count == 0 {
                        self.logger.info("stravaID NOT found - saving")
                        self.fetchAndProcess(stravaId: stravaId)
                    }
                    else {
                        self.logger.info("stravaID found - not updating")
                        self.activityIndex += 1
                        self.processNextRecord()
                    }
              

            }).execute()

        }

    }
    
    func fetchAndProcess(stravaId: Int) {
        StravaFetchFullActivity(
            stravaActivityId: stravaId,
            completionHandler: {
                activityRecord in

// NEED TO WORK OUT WAY OF INTEGRATING CACHE!!!
//                    activityRecord.save(dataCache: self.dataCache)
                CKSaveOrUpdateActivityRecord(
                    activityRecord: activityRecord,
                    completionFunction: {_ in
                        self.activityIndex += 1
                        self.processNextRecord()
                    }
                ).execute()

            },
            failureCompletionHandler: self.failureCompletionHandler
        ).execute()
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
                self.logger.error("Error : \(error.localizedDescription) :: \(error)")
                if error.code == 429 {
                    self.logger.error("Strava API limit exceeded")
                }
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

                guard let streams = streams else {
                    self.logger.info("No streams returned")
                    self.completionHandler([])
                    return
                }
                self.logger.info("Got streams")
                self.completionHandler(streams)

            }, failure: { (error: NSError) in
                self.stravaBusyStatus(false)
                // Note this happens when no streams, so not really an error!
                self.logger.error("Error in streams - none returned : \(error.localizedDescription)")
                self.completionHandler([])
//                self.failureCompletionHandler()
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
            let activityRecord = ActivityRecord(fromStravaActivity: stravaActivity)
            
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


/// Upload strava activity - this is asynchronous - just get an uploadId as completion. Use this poll for actual strava activity...
class StravaUploadActivity: StravaOperation {

    var activityRecord: ActivityRecord
    var completionHandler: (Int) -> Void
    var failureCompletionHandler: () -> Void

    
    init(activityRecord: ActivityRecord,
         completionHandler: @escaping (Int) -> Void,
         failureCompletionHandler: @escaping () -> Void = { },
         forceReauth: Bool = false,
         forceRefresh: Bool = false) {
        
        self.activityRecord = activityRecord
        self.completionHandler = completionHandler
        self.failureCompletionHandler = failureCompletionHandler
        

        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)


    }
    
    
    /// If tcx asset alreday loaded use it, else fetch from cloudkit and call upload on completion
    func execute() {
        
        if let asset = activityRecord.tcxAsset {

            let fileURL = asset.fileURL!
            
            do {
                let tcxgzData = try Data(contentsOf: fileURL)
                self.logger.log("Got tcx data of size \(tcxgzData.count)")
                
                upload(tcxgzData: tcxgzData)

            } catch {
                self.logger.error("Can't get data at url:\(fileURL)")
                self.failureCompletionHandler()
            }
        } else {
            CKFetchTcxAsset(recordID: activityRecord.recordID,
                            completionHandler: upload,
                            failureCompletionHandler: self.failureCompletionHandler
            ).execute()
        }

    }

    /// Perform upload to strava - call configured completion handlers on success / failure
    func upload(tcxgzData: Data) {
        
        let uploadData = UploadData(activityType: ActivityType(rawValue: activityRecord.stravaType) ?? .ride,
                                    name: activityRecord.name,
                                    description: nil,
                                    private: false,
                                    trainer: nil,
                                    externalId: activityRecord.recordID.recordName,
                                    dataType: .tcxGz,
                                    file: tcxgzData)


        if validToken(execFunction: self.execute, failureCompletionHandler: failureCompletionHandler) {

            StravaClient.sharedInstance.upload(Router.uploadFile(upload: uploadData), upload: uploadData, result: { [weak self] (uploadStatus: UploadStatus?) in

                guard let self = self else { return }
                self.stravaBusyStatus(false)

                guard let uploadStatus = uploadStatus else {
                    self.logger.error("Error : No Upload status")
                    self.failureCompletionHandler()
                    return }
                
                self.logger.info("Upload Status \(uploadStatus)")

                let uploadId = uploadStatus.id!
                self.pollUploadStatus(uploadId: uploadId,
                                      retryCount: 5,
                                      currentRetry: 1)
                

            }, failure: { (error: NSError) in
                self.stravaBusyStatus(false)
                self.logger.error("Error : \(error.localizedDescription) :: \(error)")
                if error.code == 429 {
                    self.logger.error("Strava API limit exceeded")
                }
                self.failureCompletionHandler()
            })
        }
    }
    
    func pollUploadStatus(uploadId: Int, retryCount: Int, currentRetry: Int) {
        
        let PAUSE_TIME: TimeInterval = 3  // Delay between attempts as Strava processes the upload..
        
        if currentRetry >= retryCount {
            self.logger.error("Polling complete without success :: \(currentRetry)")
            self.failureCompletionHandler()
        }
        
        else {

            // Poll for upload status...
            DispatchQueue.main.asyncAfter(deadline: .now() + PAUSE_TIME) {
                
                self.logger.info("Polling upload status : Count :: \(currentRetry)")
                
                StravaClient.sharedInstance.request(Router.uploads(id: uploadId), result: { /*[weak self]*/ (status: UploadStatus?) in
//                    guard let self = self else {
//                        print("No Self!")
//                        return
//                    }
                    guard let status = status else {
                        self.logger.error("Error : No Upload status")
                        self.failureCompletionHandler()
                        return
                    }
                    if let error = status.error {
                        self.logger.error("Upload failed with error : \(error)")
                        self.failureCompletionHandler()
                        return
                    } else if let stravaId = status.activityId {
                        // We have a valid activityID so the upload is considered complete.
                        // However, note that segment processing can continue for quite a while.
                        self.logger.info("Polling completed successfully :: retry count \(currentRetry) :: id \(stravaId)")
                        self.activityRecord.stravaId = stravaId
                        StravaUpdateActivity(activityRecord: self.activityRecord,
                                             completionHandler: { _ in self.completionHandler(stravaId)},
                                             failureCompletionHandler: { self.completionHandler(stravaId)}).execute()
                    } else {
                        // Start another timer
                        self.logger.info("Trying again...")
                        self.pollUploadStatus(uploadId: uploadId, retryCount: retryCount, currentRetry: currentRetry + 1)
                    }
                }, failure: { (error: NSError) in
                    debugPrint(error)
                })
                
                
            }
        }

    }
    
}


/// Update a strava activity - allows name, description, type to be changed
class StravaUpdateActivity: StravaOperation {

    var activityRecord: ActivityRecord
    var completionHandler: (StravaActivity) -> Void
    var failureCompletionHandler: () -> Void
    var stravaActivityRecord: StravaActivity?

    
    init(activityRecord: ActivityRecord,
         completionHandler: @escaping (StravaActivity) -> Void,
         failureCompletionHandler: @escaping () -> Void = { },
         forceReauth: Bool = false,
         forceRefresh: Bool = false) {
        
        self.activityRecord = activityRecord
        self.completionHandler = completionHandler
        self.failureCompletionHandler = failureCompletionHandler
        
        var json = JSON()

        if let id = activityRecord.stravaId {
            json.dictionaryObject = [
                "id": id,
                "description": activityRecord.activityDescription,
                "name": activityRecord.name,
                "sport_type": activityRecord.stravaType
            ]
            
            self.stravaActivityRecord = StravaActivity(json)
        }

        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)


    }
    
    
    /// If tcx asset alreday loaded use it, else fetch from cloudkit and call upload on completion
    func execute() {
        
        guard let updatableActivity = stravaActivityRecord else {
            self.logger.error("Error : Activity Record is not saved to strava, so cannot be updated")
            return
        }
        if validToken(execFunction: self.execute, failureCompletionHandler: failureCompletionHandler) {

            StravaClient.sharedInstance.request(Router.updateActivity(activity: updatableActivity), result: { [weak self] (activity: StravaActivity?) in

                guard let self = self else { return }
                self.stravaBusyStatus(false)
                self.logger.info("Update completed :: \(activity?.name ?? "NONE")")
                guard let activity = activity else { return }

                self.completionHandler(activity)

            }, failure: { (error: NSError) in
                self.stravaBusyStatus(false)
                self.logger.error("Error : \(error.localizedDescription) :: \(error)")
                if error.code == 429 {
                    self.logger.error("Strava API limit exceeded")
                }
                self.failureCompletionHandler()
            })

        }

    }

}

