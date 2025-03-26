//
//  FetchLatestActivities.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 21/03/2025.
//

import Foundation


class StravaFetchLatestActivities: StravaOperation {
    
    var page: Int = 1
    var perPage: Int
    var after: Date
    var activityIndex: Int = 0
    var stravaActivityPage: [StravaActivity] = []
    var thisFetchDate: Int
    var completionHandler: () -> Void
    var failureCompletionHandler: () -> Void
    var asyncProgressNotifier: AsyncProgress?
    
    init(perPage: Int = 30,
         after: Date? = nil,
         forceReauth: Bool = false,
         forceRefresh: Bool = false,
         completionHandler: @escaping () -> Void,
         failureCompletionHandler: @escaping () -> Void = { },
         asyncProgressNotifier: AsyncProgress? = nil) {
        
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
        self.asyncProgressNotifier = asyncProgressNotifier
        
        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)

    }
    
    func execute() {
        getNextPage()
    }
    
    func getNextPage() {

        if let notifier = asyncProgressNotifier {
            notifier.majorIncrement(message: "Fetching Page...")
        }

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
            if let notifier = asyncProgressNotifier {
                notifier.majorIncrement(message: "Fetch completed")
            }
            completionHandler()
            
        }
        else {
            page += 1
            activityIndex = 0
            if let notifier = asyncProgressNotifier {
                notifier.minorIncrement(message: "Fetched record list")
            }
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
            if let notifier = asyncProgressNotifier {
                notifier.resetStatus()
                notifier.majorIncrement(message: "Processing \(self.stravaActivityPage[activityIndex].name ?? String(stravaId))")
            }
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
        
        if let notifier = asyncProgressNotifier {
            notifier.majorIncrement(message: "Fetching \(stravaId)")
        }
        
        StravaFetchFullActivity(
            stravaActivityId: stravaId,
            completionHandler: {
                activityRecord in

// NEED TO WORK OUT WAY OF INTEGRATING CACHE!!!
//                    activityRecord.save(dataCache: self.dataCache)
                
                if let notifier = self.asyncProgressNotifier {
                    notifier.majorIncrement(message: "Saving / Updating : \(activityRecord.name)")
                }
                
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
