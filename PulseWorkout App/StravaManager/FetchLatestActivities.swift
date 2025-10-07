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
    var dataCache: DataCache
    
    init(perPage: Int = 30,
         after: Date? = nil,
         forceReauth: Bool = false,
         forceRefresh: Bool = false,
         completionHandler: @escaping () -> Void,
         failureCompletionHandler: @escaping () -> Void = { },
         dataCache: DataCache,
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
        self.dataCache = dataCache
        
        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)

    }
    
    func execute() {
        getNextPage()
    }
    
    func getNextPage() {

        if let notifier = asyncProgressNotifier {
            notifier.majorIncrement(message: "Fetching new activities...")
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
                notifier.majorIncrement(message: "Fetch complete")
            }
            completionHandler()
            
        }
        else {
            page += 1
            activityIndex = 0
            if let notifier = asyncProgressNotifier {
                notifier.minorIncrement(message: "Fetched next activity list")
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
            let stravaName = self.stravaActivityPage[activityIndex].name ?? String(stravaId)
            
            
            self.logger.info("processing stravaID \(stravaId)")
            if let notifier = asyncProgressNotifier {
                notifier.resetStatus()
                notifier.majorIncrement(message: "Processing \(stravaName)")
            }
            CKQueryForStravaIdOperation(stravaId: stravaId,
                                        completionFunction: {
                ckRecords in
                    if ckRecords.count == 0 {
                        self.logger.info("stravaID NOT found - saving")
                        self.fetchAndProcess(stravaId: stravaId, stravaName: stravaName)
                    }
                    else {
                        self.logger.info("stravaID found - not updating")
                        self.activityIndex += 1
                        self.processNextRecord()
                    }
              

            }).execute()

        }

    }
    
    func fetchAndProcess(stravaId: Int, stravaName: String) {
        
        if let notifier = asyncProgressNotifier {
            notifier.majorIncrement(message: "Fetching \(stravaName)")
        }
        
        StravaFetchFullActivity(
            stravaActivityId: stravaId,
            completionHandler: {
                activityRecord in

                /// Save or update the record
                activityRecord.save(dataCache: self.dataCache)
                
                if let notifier = self.asyncProgressNotifier {
                    notifier.majorIncrement(message: "Saving / Updating : \(activityRecord.name)")
                }
                self.activityIndex += 1
                self.processNextRecord()

            },
            failureCompletionHandler: self.failureCompletionHandler
        ).execute()
    }
    
}
