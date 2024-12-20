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
        print("error \(error.localizedDescription)")
        return nil
    }

    return cachePath
}

/// Get URL for  file in cache directory
func CacheURL(fileName: String) -> URL? {

    guard let cachePath = getCacheDirectory() else { return nil }

    return cachePath.appendingPathComponent(fileName)
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
    
    let containerName: String = "iCloud.MurrayNet.Aleph"
    static var zoneName: String = "Aleph_Zone"
    
    var container: CKContainer!
    var database: CKDatabase!
    var zoneID: CKRecordZone.ID!
    
    @Published var UIRecordSet: [ActivityRecord] = []
    @Published var fetching: Bool = false
    @Published var fetchComplete: Bool = false

    /// Activity record fetched and used in detail display
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
        
        container = CKContainer(identifier: containerName)
        database = container.privateCloudDatabase
        zoneID = CKRecordZone.ID(zoneName: DataCache.zoneName)
                
/*
        Task {
            do {
                try await createCKZoneIfNeeded()
            } catch {
                logger.error("error \(error)")
            }

        }
  */

        // Create subscription for record change notifications
        createQuerySubscription()
        
        if readCache {
            _ = read()
                        
            if !dirty() {
                refreshCache()
            }
            else {
                flushCache()
            }
        }

    }
    
    /// Class function to create a new recordID in correct zone, given a record name
    class func getCKRecordID(recordName: String) -> CKRecord.ID {
        return CKRecord.ID(recordName: recordName, zoneID: CKRecordZone.ID(zoneName: zoneName))
    }

    /// Class function to create a new recordID in correct zone from scratch
    class func getCKRecordID() -> CKRecord.ID {
        let recordName = CKRecord.ID().recordName
        return CKRecord.ID(recordName: recordName, zoneID: CKRecordZone.ID(zoneName: zoneName))
    }
    
    
    func refreshUI() {
        
        if !dirty() {
            refreshCache()
        }
        else {
            flushCache()

            updateUI()
        }
        
    }
    
    
    /// push changes in cache to cloudkit
    private func flushCache() {
        saveAndDeleteRecord(recordsToSave: toBeSavedCKRecords(),
                            recordIDsToDelete: toBeDeletedIDs())
    }
    
    
    /// Copy cache contents to User Interface list - trigger view update
    private func updateUI() {
        
        DispatchQueue.main.async { [self] in
            self.UIRecordSet = self.cache()
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
 
    
    func add(activityRecord: ActivityRecord) {
        
        activityRecord.setToSave(true)
        activities.insert(activityRecord, at: 0)
        
        if cache().count > cacheSize {
            activities.removeLast()
        }
        
        UIRecordSet.insert(activityRecord, at: 0)

        _ = write()
        
        flushCache()

    }

    
    /// Test if this recordId is in the cache
    /// If not in cache then returns nil. If in cache returns index
    private func cachedIndex(recordID: CKRecord.ID) -> Int? {
        
        return activities.firstIndex(where: { $0.recordName == recordID.recordName })
        
    }
    
    /// Remove record from UI
    func removeFromUI(recordID: CKRecord.ID) {
        
        guard let index = UIRecordSet.firstIndex(where: { $0.recordName == recordID.recordName }) else {return}
        
        UIRecordSet.remove(at: index)
    }
    
    
    func delete(recordID: CKRecord.ID) {
        
        removeFromUI(recordID: recordID)
        
        guard let index = cachedIndex(recordID: recordID) else {
            // Record is not in cache, just attempt deletion
            saveAndDeleteRecord(recordsToSave: [], recordIDsToDelete: [recordID])
            return
        }
               
        // Record is in cache, mark to delete in cahce and then flush cache
        activities[index].toDelete = true
        activities[index].deleteTrackRecord()
        
        logger.debug("DELETED OK :\(index) \(recordID.recordName)")
        _ = write()
        
        flushCache()
        
    }
    
    
    /// Remove item from cache - call once deleted from cloudkit
    func removeFromCache(recordID: CKRecord.ID) {
        
        guard let index = activities.firstIndex(where: { $0.recordName == recordID.recordName }) else {
            return
        }

        activities.remove(at: index)
        
        _ = write()
        
    }
    

    /// Returns list of to-be-saved activity records
    private func toBeSaved() -> [ActivityRecord] {
        
        return activities.filter{ ($0.toSave == true) && ($0.toDelete == false) }

    }

    
    /// Returns list of to-be-deleted activity records
    private func toBeDeleted() -> [ActivityRecord] {
        
        return activities.filter{ $0.toDelete == true }

    }

    private func toBeSavedCKRecords() -> [CKRecord] {
        
        return activities.filter{ ($0.toSave == true) && ($0.toDelete == false) }.map( { $0.asCKRecord() })

    }
    
    /// Returns list of to-be-deleted activity records
    private func toBeDeletedIDs() -> [CKRecord.ID] {
        
        return activities.filter{ $0.toDelete == true }.map( {$0.recordID} )

    }

    
    private func cache() -> [ActivityRecord] {
        
        return activities.filter{ $0.toDelete == false }
        
    }
    
    
    /// Does the cache have outstanding additions or deletions to be written to CloudKit?
    private func dirty() -> Bool {
        
        return (toBeSaved().count > 0) || (toBeDeleted().count > 0)
        
    }
    
    /// Get URL for JSON file
    private func CacheURL(fileName: String) -> URL? {

        guard let cachePath = getCacheDirectory() else { return nil }

        return cachePath.appendingPathComponent(fileName)
    }


    /// Read cache from JSON file in cache folder
    private func read() -> Bool {

        guard let cacheURL = CacheURL(fileName: cacheFile) else { return false }

        do {
            let data = try Data(contentsOf: cacheURL)
            let decoder = JSONDecoder()
            let JSONData = try decoder.decode(DataCache.self, from: data)
            activities = []
            
            for activity in JSONData.activities {
//                logger.log("activity \(activity.recordName ?? "xxx")  toBeSaved status \(activity.toSave) -- toDelete status \(activity.toDelete)")
                // create recordID from recordName as recordID not serialised to JSON
                activity.recordID = DataCache.getCKRecordID(recordName: activity.recordName)
//                CKRecord.ID(recordName: activity.recordName, zoneID: zoneID)
//                activity.recordID = CKRecord.ID(recordName: activity.recordName)
//                let str = activity.mapSnapshotURL?.absoluteString as! String
//                logger.log("map snapshot : \(str)")
                // set toSavePublished equal to toSave
                activity.setToSave(activity.toSave)
                activities.append(activity)
            }
            
            updateUI()
            
            return true
        }
        catch {
            logger.error("error:\(error.localizedDescription)")
            return false
        }
    }
    
    
    /// Write entire cache to JSON file in cache folder
    private func write() -> Bool {
        
        guard let cacheURL = CacheURL(fileName: cacheFile) else { return false }
        
        logger.log("Writing cache to JSON file")
//        logger.debug("Activities \(self.activities)")
        do {
            let data = try JSONEncoder().encode(self)
//            let jsonString = String(data: data, encoding: .utf8)
//            logger.log("JSON : \(String(describing: jsonString))")
            do {
                try data.write(to: cacheURL)

                return true
            }
            catch {
                logger.error("error \(error.localizedDescription)")
                return false
            }

        } catch {
            logger.error("Error enconding cache")
            return false
        }

    }

    
    private func refreshCache() {
        
        fetchRecordBlock(startDate: nil,
                         qualityOfService: .userInitiated,
                         blockCompletionFunction: refreshCacheCompletion)
        
    }
  
    
    private func refreshCacheCompletion(records : [ActivityRecord] ) -> Void {
        
        // copy temporary array to main array and write to local cache
        // only if no unsaved / undeleted items in local cache otherwise cloud view is out of date!
        
//        logger.log("refesh cache completion")
//        logger.log("Top record = \(records[0].name)")
//        DispatchQueue.main.async {
            if !self.dirty() {
                self.activities = records
                _ = self.write()
//            }
//            self.UIRecordSet = records
            self.updateUI()
        }

        
    }
    
    
    func fetchNextBlock() {
        
        if fetching {
            return
        }
        if fetchComplete {
            return
        }
        
        let latestUIDate = UIRecordSet.last?.startDateLocal ?? nil
        logger.log("Fetch next block with start date \(String(describing: latestUIDate?.formatted()))")
        fetchRecordBlock(startDate: latestUIDate,
                         qualityOfService: .userInitiated,
                         blockCompletionFunction: nextBlockCompletion)
        
    }
    
    
    private func nextBlockCompletion(records : [ActivityRecord] ) -> Void {
        
        logger.log("next block fetch completion")
        DispatchQueue.main.async {
            self.UIRecordSet += records
        }
    }
    
    
    private func fetchRecordBlock(startDate: Date?, qualityOfService: QualityOfService, blockCompletionFunction: @escaping ([ActivityRecord]) -> ()) {
        

        refreshList = []
        fetching = true
        fetchComplete = false
        
        var pred = NSPredicate(value: true)
        if startDate != nil {
            pred = NSPredicate(format: "startDateLocal < %@", startDate! as CVarArg)
        }
        let sort = NSSortDescriptor(key: "startDateLocal", ascending: false)
        let query = CKQuery(recordType: "activity", predicate: pred)
        query.sortDescriptors = [sort]

        let operation = CKQueryOperation(query: query)

        operation.desiredKeys = ["name", "type", "sportType", "startDateLocal", "elapsedTime", "pausedTime", "movingTime",
                                 "activityDescription", "distance", "totalAscent", "totalDescent",
                                 "averageHeartRate", "averageCadence", "averagePower", "averageSpeed",
                                 "maxHeartRate", "maxCadence", "maxPower", "maxSpeed",
                                 "activeEnergy", "timeOverHiAlarm", "timeUnderLoAlarm", "hiHRLimit", "loHRLimit", "mapSnapshot" ]
        operation.resultsLimit = cacheSize
        operation.qualityOfService = qualityOfService


        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                let newActivityRecord = ActivityRecord(fromCKRecord: record, settingsManager: self.settingsManager)

                DispatchQueue.main.async {
                    self.refreshList.append(newActivityRecord)
                }
                break
                
            case .failure(let error):
                self.logger.error( "Fetch failed \(String(describing: error))")
                
                break
            }
        }
            
        operation.queryResultBlock = { result in

            DispatchQueue.main.async {
                self.fetching = false
            }

            switch result {
            case .success:

                if self.refreshList.count < self.cacheSize {
                    DispatchQueue.main.async {
                        self.fetchComplete = true
                    }
                }
                blockCompletionFunction(self.refreshList)
                
                break
                    
            case .failure(let error):

                switch error {
                case CKError.accountTemporarilyUnavailable,
                    CKError.networkFailure,
                    CKError.networkUnavailable,
                    CKError.serviceUnavailable,
                    CKError.zoneBusy:
//                    CKError.notAuthenticated: //REMOVE!!
                    
                    self.logger.log("temporary refresh error")

                    
                default:
                    self.logger.error("permanent refresh error - not retrying")
                }
                self.logger.error( "Fetch failed \(String(describing: error))")
                break
            }

        }
        
        database.add(operation)

    }

    
    func CKForceUpdate(activityCKRecord: CKRecord, completionFunction: @escaping (CKRecord?) -> Void) {
        logger.log("updating \(activityCKRecord.recordID)")
        
        database.modifyRecords(saving: [activityCKRecord], deleting: [], savePolicy: .changedKeys) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let records):
                    print("Success Records : \(records)")
 
                    for recordResult in records.saveResults {
    
                        switch recordResult.value {
                        case .success(let record):
                            self.logger.log("Record updated \(record)")
                            completionFunction(record)
                            _ = self.write()
                        case .failure(let error):
                            self.logger.error("Single Record update failed with error \(error.localizedDescription)")
                            completionFunction(nil)
                        }

                    }

                case .failure(let error):
                    self.logger.error("Batch Record update failed with error \(error.localizedDescription)")
                    // Delete temporary image file
                    completionFunction(nil)
                }
                

            }
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
    

    
    func saveAndDeleteRecord(recordsToSave: [CKRecord],
                             recordIDsToDelete: [CKRecord.ID]) {

        self.logger.log("Saving records: \(recordsToSave.map( {$0.recordID} ))")
        self.logger.log("Deleting records: \(recordIDsToDelete)")


        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: recordsToSave, recordIDsToDelete: recordIDsToDelete)
        modifyRecordsOperation.qualityOfService = .utility
        modifyRecordsOperation.isAtomic = false
        
        // recordFetched is a function that gets called for each record retrieved
        modifyRecordsOperation.perRecordSaveBlock = { (recordID: CKRecord.ID, result: Result<CKRecord, any Error>) in
            switch result {
            case .success(let record):
                // populate displayActivityRecord - NOTE tcx asset was fetched, so will parse entire track record
                
                guard let savedActivityRecord = self.activities.filter({ $0.recordName == recordID.recordName }).first else {return}
                self.logger.log("Saved")
                
                savedActivityRecord.deleteTrackRecord()
                savedActivityRecord.setToSave(false)
                
                _ = self.write()
                
                break
                
            case .failure(let error):

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
                    guard let savedActivityRecord = self.activities.filter({ $0.recordName == recordID.recordName }).first else {return}
                    savedActivityRecord.deleteTrackRecord()
                    savedActivityRecord.setToSave(false)
                    
                    _ = self.write()
                    
                default:
                    self.logger.error("permanent error")
                    
                }
                
                self.logger.error("Save failed with error : \(error.localizedDescription)")
                
                break
            }

        }
        
        modifyRecordsOperation.perRecordDeleteBlock = { (recordID: CKRecord.ID, result: Result<Void, any Error>) in
            switch result {
            case .success:
                self.logger.log("deleted and removed \(recordID)")
                self.removeFromCache(recordID: recordID)
                
                break
                
            case .failure(let error):
                switch error {
                case CKError.unknownItem:
                    self.logger.debug("item being deleted had not been saved")
                    self.removeFromCache(recordID: recordID)
                    return
                default:
                    self.logger.error("Deletion failed with error : \(error.localizedDescription)")
                    return
                }
            }
        }
            
        modifyRecordsOperation.modifyRecordsResultBlock = { (operationResult : Result<Void, any Error>) in
        
            switch operationResult {
            case .success:
                self.logger.info("Record modify completed")

                break
                
            case .failure(let error):
                self.logger.error( "modify failed \(String(describing: error))")

                break
            }

        }
        
        self.database.add(modifyRecordsOperation)

    }
    
    
    func fetchAllRecordIDs(recordCompletionFunction: @escaping (CKRecord.ID) -> ()) {
               
        var pred = NSPredicate(value: true)
        var minStartDate: Date? = nil
        var recordCount: Int = 0
        let sort = NSSortDescriptor(key: "startDateLocal", ascending: false)
        let query = CKQuery(recordType: "activity", predicate: pred)
        query.sortDescriptors = [sort]

        let operation = CKQueryOperation(query: query)

        operation.desiredKeys = ["name", "startDateLocal"]
        operation.qualityOfService = .userInitiated
        operation.resultsLimit = 200


        operation.recordMatchedBlock = { recordID, result in
            switch result {
            case .success(let record):
                recordCompletionFunction(recordID)
                recordCount += 1
                let startDate: Date = record["startDateLocal"]  ?? Date() as Date
                if minStartDate == nil {
                    minStartDate = startDate
                } else {
                    minStartDate = min(startDate, minStartDate!)
                }
                
                break
                
            case .failure(let error):
                self.logger.error( "Fetch failed for recordID \(recordID) : \(String(describing: error))")
                
                break
            }
        }
            
        operation.queryResultBlock = { result in

            switch result {
            case .success:

                self.logger.info("Record fetch successfully complete : record count \(recordCount) : min date \(minStartDate!.formatted(Date.ISO8601FormatStyle().dateSeparator(.dash)))")
                
                break
                    
            case .failure(let error):

                switch error {
                case CKError.accountTemporarilyUnavailable,
                    CKError.networkFailure,
                    CKError.networkUnavailable,
                    CKError.serviceUnavailable,
                    CKError.zoneBusy:
                    
                    self.logger.log("temporary refresh error")

                    
                default:
                    self.logger.error("permanent refresh error - not retrying")
                }
                self.logger.error( "Fetch failed \(String(describing: error))")
                break
            }

        }
        
        database.add(operation)

    }

    
 
}
