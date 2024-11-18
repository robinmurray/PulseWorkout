//
//  DataCache.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 03/12/2023.
//

import Foundation
import CloudKit
import os


func getCacheDirectory() -> URL? {

    let cachePath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("pulseWorkout")
    do {
        try FileManager.default.createDirectory(at: cachePath, withIntermediateDirectories: true)
    } catch {
        print("error \(error)")
        return nil
    }

    return cachePath
}

func clearCache() {
    let fm = FileManager.default

    do {
        let files = try fm.contentsOfDirectory(atPath: getCacheDirectory()!.path)
//            let jsonFiles = files.filter{ $0.pathExtension == "json" }
        for file in files {
            let path = getCacheDirectory()!.appendingPathComponent(file)
            do {
                try FileManager.default.removeItem(at: path)

            } catch {
                print(error)
            }

            
        }
    } catch {
        print("Directory search failed!")
        // failed to read directory – bad permissions, perhaps?
    }
}

class FullActivityRecordCache: NSObject {
    
    private var cache: [ActivityRecord] = []
    let cache_SIZE = 5
    
    func add(activityRecord: ActivityRecord) {
        cache.insert(activityRecord, at: 0)
        
        if cache.count > cache_SIZE {
            cache.removeLast()
        }
    }
    
    func get(recordID: CKRecord.ID) -> ActivityRecord? {
        guard let index = cache.firstIndex(where: {$0.recordID == recordID}) else {
            return nil
        }
        
        // Move selected record to top of array
        let activityRecord = cache[index]
        cache.remove(at: index)
        cache.insert(activityRecord, at: 0)
        return activityRecord
    }
}

class DataCache: NSObject, Codable, ObservableObject {
    
    var settingsManager: SettingsManager!
    
    var container: CKContainer!
    var database: CKDatabase!
//    var zoneID: CKRecordZone.ID!
    
    @Published var UIRecordSet: [ActivityRecord] = []

    /// Activity record fetched and used in detail display
//    var displayActivityRecord: ActivityRecord?
    var fullActivityRecordCache: FullActivityRecordCache = FullActivityRecordCache()

       
    let cacheSize = 50
    let cacheFile = "activityCache.act"
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "dataCache")
    private var activities: [ActivityRecord] = []
    private var refreshList: [ActivityRecord] = []
    private var synchTimer: Timer?
   
    // set CodingKeys to define which variables are stored to JSON file
    private enum CodingKeys: String, CodingKey {
        case activities
    }

    init(settingsManager: SettingsManager, readCache: Bool = true) {

        super.init()
        self.settingsManager = settingsManager
        
        container = CKContainer(identifier: "iCloud.CloudKitLesson")
        database = container.privateCloudDatabase
//        zoneID = CKRecordZone.ID(zoneName: "CKL_Zone")
        
/*
        Task {
            do {
                try await createCKZoneIfNeeded()
            } catch {
                logger.error("error \(error)")
            }

        }
  */

        if readCache {
            _ = read()
            
            
            if !dirty() {
                refresh()
            }
            else {
                startSynchTimer()
            }
        }

    }
    
    private func createCKZoneIfNeeded(zoneID: CKRecordZone.ID) async throws {

        guard !UserDefaults.standard.bool(forKey: "zoneCreated") else {
            return
        }

        logger.log("creating zone")
        let newZone = CKRecordZone(zoneID: zoneID)
        _ = try await database.modifyRecordZones(saving: [newZone], deleting: [])

        UserDefaults.standard.set(true, forKey: "zoneCreated")
    }
 

    func updateUI() {
        
        DispatchQueue.main.async {
            self.UIRecordSet = self.cache()
        }
        
    }
    
    func add(activityRecord: ActivityRecord) {
        
        activityRecord.setToSave(true)
        activities.insert(activityRecord, at: 0)
        
        if cache().count > cacheSize {
            activities.removeLast()
        }
        
        _ = write()
        
        updateUI()
        
        startSynchTimer()

    }
    
    func delete(recordID: CKRecord.ID) {
               
        guard let index = activities.firstIndex(where: { $0.recordName == recordID.recordName }) else {
            logger.log("DELETION not Found!! ")
            return
        }

        activities[index].toDelete = true
        activities[index].deleteTrackRecord()
        
        logger.debug("DELETED OK :\(index) \(recordID.recordName)")
        _ = write()
        
        updateUI()
        
        startSynchTimer()
        
    }
    
    /// Remove item from cache - call once deleted from cloudkit
    func remove(recordID: CKRecord.ID) {
        
        guard let index = activities.firstIndex(where: { $0.recordName == recordID.recordName }) else {
            return
        }

        activities.remove(at: index)
        
        _ = write()
        
    }

    /// Returns list of to-be-saved activity records
    func toBeSaved() -> [ActivityRecord] {
        
        return activities.filter{ ($0.toSave == true) && ($0.toDelete == false) }

    }

    /// Returns list of to-be-deleted activity records
    func toBeDeleted() -> [ActivityRecord] {
        
        return activities.filter{ $0.toDelete == true }

    }
    
    func cache() -> [ActivityRecord] {
        
        return activities.filter{ $0.toDelete == false }
        
    }
    
    /// Does the cache have outstanding additions or deletions to be written to CloudKit?
    func dirty() -> Bool {
        
        return (toBeSaved().count > 0) || (toBeDeleted().count > 0)
        
    }
    
    /// Get URL for JSON file
    func CacheURL(fileName: String) -> URL? {

        guard let cachePath = getCacheDirectory() else { return nil }

        return cachePath.appendingPathComponent(fileName)
    }


    /// Read cache from JSON file in cache folder
    func read() -> Bool {

        guard let cacheURL = CacheURL(fileName: cacheFile) else { return false }

        do {
            let data = try Data(contentsOf: cacheURL)
            let decoder = JSONDecoder()
            let JSONData = try decoder.decode(DataCache.self, from: data)
            activities = []
            
            for activity in JSONData.activities {
                logger.log("activity \(activity.recordName ?? "xxx")  toBeSaved status \(activity.toSave) -- toDelete status \(activity.toDelete)")
                // create recordID from recordName as recordID not serialised to JSON
//                activity.recordID = CKRecord.ID(recordName: activity.recordName, zoneID: zoneID)
                activity.recordID = CKRecord.ID(recordName: activity.recordName)

                // set toSavePublished equal to toSave
                activity.setToSave(activity.toSave)
                activities.append(activity)
            }
            
            updateUI()
            
            return true
        }
        catch {
            logger.error("error:\(error)")
            return false
        }
    }
    
    
    /// Write entire cache to JSON file in cache folder
    func write() -> Bool {
        
        guard let cacheURL = CacheURL(fileName: cacheFile) else { return false }
        
        logger.log("Writing cache to JSON file")
        logger.debug("Activities \(self.activities)")
        do {
            let data = try JSONEncoder().encode(self)
//            let jsonString = String(data: data, encoding: .utf8)
//            logger.log("JSON : \(String(describing: jsonString))")
            do {
                try data.write(to: cacheURL)
                
                updateUI()

                return true
            }
            catch {
                logger.error("error \(error)")
                return false
            }

        } catch {
            logger.error("Error enconding cache")
            return false
        }

    }

    
    @objc func refresh() {
        
        refreshList = []
        let pred = NSPredicate(value: true)
        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
        let query = CKQuery(recordType: "activity", predicate: pred)
        query.sortDescriptors = [sort]

        let operation = CKQueryOperation(query: query)

        operation.desiredKeys = ["name", "type", "sportType", "startDateLocal", "elapsedTime", "pausedTime", "movingTime",
                                 "activityDescription", "distance", "totalAscent", "totalDescent",
                                 "averageHeartRate", "averageCadence", "averagePower", "averageSpeed", "activeEnergy", "timeOverHiAlarm", "timeUnderLoAlarm", "hiHRLimit", "loHRLimit" ]
        operation.resultsLimit = cacheSize
// FIX?        operation.configuration.timeoutIntervalForRequest = 30


        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                // TODO: Do something with the record that was received.
                let myRecord = ActivityRecord(fromCKRecord: record, settingsManager: self.settingsManager)

                DispatchQueue.main.async {
                    self.logger.debug("Adding to cache : \(myRecord)")
                    self.refreshList.append(myRecord)
                }
                break
                
            case .failure(let error):
                // TODO: Handle per-record failure, perhaps retry fetching it manually in case an asset failed to download or something like that.
                self.logger.error( "Fetch failed \(String(describing: error))")
                
                break
            }
        }
            
        operation.queryResultBlock = { result in

            switch result {
            case .success:

                for record in self.refreshList {
                    self.logger.debug( "\(record.description())" )
                }
                
                // copy temporary array to main array and write to local cache
                // only if no unsaved / undeleted items in local cache otherwise cloud view is out of date!
                DispatchQueue.main.async {
                    if !self.dirty() {
                        self.activities = self.refreshList
                        _ = self.write()
                    }
                }


                break
                    
            case .failure(let error):

                switch error {
                case CKError.accountTemporarilyUnavailable,
                    CKError.networkFailure,
                    CKError.networkUnavailable,
                    CKError.serviceUnavailable,
                    CKError.zoneBusy:
//                    CKError.notAuthenticated: //REMOVE!!
                    
                    self.logger.log("temporary refresh error - set up retry")
                        self.startDeferredRefresh()
                    
                default:
                    self.logger.error("permanent refresh error - not retrying")
                }
                self.logger.error( "Fetch failed \(String(describing: error))")
                break
            }

        }
        
        database.add(operation)

    }

    func startDeferredRefresh() {
        let deferredTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(refresh), userInfo: nil, repeats: false)
        deferredTimer.tolerance = 5
    }

    
    
    func CKDelete(recordID: CKRecord.ID) {
        
        self.logger.log("deleting \(recordID)")
        
        database.delete(withRecordID: recordID) { (ckRecordID, error) in
            
            if let error = error {
                self.logger.error("\(error.localizedDescription)")
                
                switch error {
                case CKError.unknownItem:
                    self.logger.debug("item being deleted had not been saved")
                    self.remove(recordID: recordID)
                    return
                default:
                    return
                }
                
            }
            
            guard let id = ckRecordID else {
                return
            }
            
            self.logger.log("deleted and removed \(id)")
            self.remove(recordID: recordID)
            
        }
    }

    func CKSave(activityRecord: ActivityRecord) {

        let CKRecord = activityRecord.asCKRecord()
        logger.log("saving \(activityRecord.recordID!)")

        database.save(CKRecord) { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    switch error {
                    case CKError.accountTemporarilyUnavailable,
                        CKError.networkFailure,
                        CKError.networkUnavailable,
                        CKError.serviceUnavailable,
                        CKError.zoneBusy:
                        
                        self.logger.log("temporary error")
                    
                    case CKError.serverRecordChanged:
                        // Record already exists- shouldn't happen, but!
                        self.logger.error("record already exists!")
                        activityRecord.deleteTrackRecord()
                        activityRecord.setToSave(false)

                        _ = self.write()
                        
                    default:
                        self.logger.error("permanent error")

                    }
                    
                    self.logger.error("\(error)")

                } else {
                    self.logger.log("Saved")

                    activityRecord.deleteTrackRecord()
                    activityRecord.setToSave(false)
                    
                    _ = self.write()
                }
            }
        }
        
    }

    
    func startSynchTimer() {
        if self.synchTimer == nil {
            self.synchTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(synch), userInfo: nil, repeats: true)
            self.synchTimer!.tolerance = 5
            logger.log("Starting synch timer")
        }
    }
    
    func stopSynchTimer() {
        
        DispatchQueue.main.async {
            if self.synchTimer != nil {
                self.synchTimer!.invalidate()
                self.synchTimer = nil
                self.logger.log("Stopping synch timer")
            }
        }
    }
    
    @objc func synch() {
        
        if !dirty() {
            stopSynchTimer()
            return
        }
        
        if toBeDeleted().count > 0 {
            CKDelete(recordID: toBeDeleted()[0].recordID)
            return
        }
        
        if toBeSaved().count > 0 {
            CKSave(activityRecord: toBeSaved()[0])
        }
        
        
        
    }

    
    func fetchRecord(recordID: CKRecord.ID,
                     completionFunction: @escaping (ActivityRecord) -> (),
                     completionFailureFunction: @escaping () -> ()) {

        self.logger.log("Fetching track file for record: \(recordID)")
        
        // check if this record already cached
        let cachedRecord = fullActivityRecordCache.get(recordID: recordID)
        if cachedRecord != nil {
            self.logger.log("Required record already cached")
            completionFunction(cachedRecord!)

            return
        }
        
        // TODO - check if record not saved yet!!!
        let unsavedActivity = activities.filter({$0.recordID == recordID && $0.toSave})
        if unsavedActivity.count != 0 {
            self.logger.log("Required record not yet saved, so copying existing object")
            let unsavedRecord = ActivityRecord(fromActivityRecord: unsavedActivity[0],
                                               settingsManager: settingsManager)
            fullActivityRecordCache.add(activityRecord: unsavedRecord)
            completionFunction(unsavedRecord)

            return
        }

        self.logger.log("fetching required record from cloudkit")
        // CKRecordID contains the zone from which the records should be retrieved
        let fetchRecordsOperation = CKFetchRecordsOperation(recordIDs: [recordID])
        fetchRecordsOperation.qualityOfService = .userInitiated
        
        // recordFetched is a function that gets called for each record retrieved
        fetchRecordsOperation.perRecordResultBlock = { (recordID: CKRecord.ID, result: Result<CKRecord, any Error>) in
            switch result {
            case .success(let record):
                // populate displayActivityRecord - NOTE tcx asset was fetched, so will parse entire track record
                let record = ActivityRecord(fromCKRecord: record, settingsManager: self.settingsManager)
                self.fullActivityRecordCache.add(activityRecord: record)

                completionFunction(record)

                break
                
            case .failure(let error):
                self.logger.error( "Fetch failed \(String(describing: error))")
                completionFailureFunction()
                
                break
            }
            

        }
        
        fetchRecordsOperation.fetchRecordsResultBlock = { (operationResult : Result<Void, any Error>) in
        
            switch operationResult {
            case .success:
                self.logger.info("Record fetch completed")
                break
                
            case .failure(let error):
                self.logger.error( "Fetch failed \(String(describing: error))")
                completionFailureFunction()
                break
            }

        }
        
        self.database.add(fetchRecordsOperation)

    }
    

    

}
