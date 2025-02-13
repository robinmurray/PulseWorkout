//
//  DataCache.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 03/12/2023.
//

import Foundation
import CloudKit
import os



func getCacheDirectory(testMode: Bool = false) -> URL? {

    let cachePath = FileManager.default.urls(for: .cachesDirectory,
                                             in: .userDomainMask).first!
        .appendingPathComponent(testMode ? "pulseWorkoutTEST" : "pulseWorkout")
    
    do {
        try FileManager.default.createDirectory(at: cachePath, withIntermediateDirectories: true)
    } catch {
        print("error \(error.localizedDescription)")
        return nil
    }

    return cachePath
}

/// Get URL for  file in cache directory
func CacheURL(fileName: String, testMode: Bool = false) -> URL? {

    guard let cachePath = getCacheDirectory(testMode: testMode) else { return nil }

    return cachePath.appendingPathComponent(fileName)
}

func clearCache(testMode: Bool = false) {
    let fm = FileManager.default

    do {
        let files = try fm.contentsOfDirectory(atPath: getCacheDirectory(testMode: testMode)!.path)
//            let jsonFiles = files.filter{ $0.pathExtension == "json" }
        for file in files {
            let path = getCacheDirectory(testMode: testMode)!.appendingPathComponent(file)
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

class DataCache: CloudKitManager, Codable {
    
    var settingsManager: SettingsManager!
    var testMode: Bool = false
    
//    let cloudKitManager: CloudKitManager = CloudKitManager()
    

    @Published var UIRecordSet: [ActivityRecord] = []


    // Activity record fetched and used in detail display
    let fullActivityRecordCache: FullActivityRecordCache = FullActivityRecordCache()
    
    // Cache for map snapshot images
    var imageCache: ImageCache!

       
    let cacheSize = 50
    let cacheFile = "activityCache.act"
    let localLogger = Logger(subsystem: "com.RMurray.PulseWorkout",
                             category: "dataCache")
    private var activities: [ActivityRecord] = []
    private var refreshList: [ActivityRecord] = []
   
    // set CodingKeys to define which variables are stored to JSON file
    private enum CodingKeys: String, CodingKey {
        case activities
    }

    init(settingsManager: SettingsManager, readCache: Bool = true, testMode: Bool = false) {

        super.init()
        self.settingsManager = settingsManager
        self.testMode = testMode
        imageCache = ImageCache(dataCache: self)
        
//        container = CKContainer(identifier: containerName)
//        database = container.privateCloudDatabase
//        zoneID = CKRecordZone.ID(zoneName: DataCache.zoneName)
                
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
//        createSubscription()
        
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
        CKsaveAndDeleteRecord(recordsToSave: toBeSavedCKRecords(),
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

        localLogger.log("creating zone")
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

    /// Test if record is cached
    func isCached(recordName: String) -> Bool {
        
        guard let _ = activities.firstIndex(where: { $0.recordName == recordName }) else {return false}
        
        return true
    }
    
    /// Test if this recordId is in the cache
    /// If not in cache then returns nil. If in cache returns index
    private func cachedIndex(recordID: CKRecord.ID) -> Int? {
        
        return activities.firstIndex(where: { $0.recordName == recordID.recordName })
        
    }
    
    private func UIIndex(recordID: CKRecord.ID) -> Int? {
        
        return UIRecordSet.firstIndex(where: { $0.recordName == recordID.recordName })
        
    }
    
    /// Remove record from UI
    func removeFromUI(recordID: CKRecord.ID) {
        
        guard let index = UIIndex(recordID: recordID) else {return}
        
        DispatchQueue.main.async {
            self.UIRecordSet.remove(at: index)
        }
    }
    
    
    func delete(recordID: CKRecord.ID) {
        
        removeFromUI(recordID: recordID)
        
        guard let index = cachedIndex(recordID: recordID) else {
            // Record is not in cache, just attempt deletion
            CKsaveAndDeleteRecord(recordsToSave: [], recordIDsToDelete: [recordID])
            return
        }
               
        // Record is in cache, mark to delete in cahce and then flush cache
        activities[index].toDelete = true
        activities[index].deleteTrackRecord()
        
        localLogger.debug("DELETED OK :\(index) \(recordID.recordName)")
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
    

    /// Change cache with changedActivityRecord.
    /// If changedActivityRecord in cache, the replace with the new record.
    /// If changedActivityRecord not in cache, then add to cache if it is the date range.
    func changeCache(changedActivityRecord: ActivityRecord) {
        
        if let index = cachedIndex(recordID: changedActivityRecord.recordID) {
            // changedActivityRecord exists in cache
            
            // Remove activityRecord from cache
            activities.remove(at: index)
            
            // Replace with changedActivityRecord
            activities.insert(changedActivityRecord, at: index)
            
            localLogger.info("Updated cache record at index \(index)")
            
            _ = write()
            
        } else {
            // changedActivityRecord does not exist in cache
            // add to cache if startDateLocal in appropriate range
            if let index = activities.firstIndex(where: {$0.startDateLocal < changedActivityRecord.startDateLocal}) {
                activities.insert(changedActivityRecord, at: index)
                
                if activities.count > cacheSize {
                    activities.removeLast()
                }
                
                localLogger.info("Inserted new cache record at index \(index)")
                
                _ = write()
            }
        }
    }
    
    
    /// Change UIRecordSet with changedActivityRecord.
    /// If changedActivityRecord in UIRecordSet, the replace with the new record.
    /// If changedActivityRecord not in UIRecordSet, then add to UIRecordSet if it is the date range.
    func changeUI(changedActivityRecord: ActivityRecord) {
        
        // UIRecordSet is published variable, so has to be changed in main async thread
        DispatchQueue.main.async {
            if let index = self.UIIndex(recordID: changedActivityRecord.recordID) {
                // changedActivityRecord exists in UIRecordSet
                
                // Remove activityRecord from UIRecordSet
                self.UIRecordSet.remove(at: index)
                
                // Replace with changedActivityRecord
                self.UIRecordSet.insert(changedActivityRecord, at: index)
                
                self.localLogger.info("Updated UI record at index \(index)")

                
            } else {
                // changedActivityRecord does not exist in UIRecordSet
                // add to UIRecordSet if startDateLocal in appropriate range
                if let index = self.UIRecordSet.firstIndex(where: {$0.startDateLocal < changedActivityRecord.startDateLocal}) {
                    
                    let recordDesc: String = self.UIRecordSet[index].name  + " : " + changedActivityRecord.startDateLocal.formatted(Date.ISO8601FormatStyle())
                    
                    let newRecordDesc: String = changedActivityRecord.name + " : " + changedActivityRecord.startDateLocal.formatted(Date.ISO8601FormatStyle())
                    
                    self.localLogger.info("found startDateLocal = \(recordDesc)")
                    self.localLogger.info("Inserting before with : \(newRecordDesc)")
                     
                    self.UIRecordSet.insert(changedActivityRecord, at: index)
                    
                    
                    self.localLogger.info("Inserted new UIRecordSet record at index \(index)")

                }
            }
        }

    }
    
    
    /// Returns list of to-be-saved activity records
    func toBeSaved() -> [ActivityRecord] {
        
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
    

    /// Read cache from JSON file in cache folder
    private func read() -> Bool {

        guard let cacheURL = CacheURL(fileName: cacheFile, testMode: testMode) else { return false }

        do {
            let data = try Data(contentsOf: cacheURL)
            let decoder = JSONDecoder()
            let JSONData = try decoder.decode(DataCache.self, from: data)
            activities = []
            
            for activity in JSONData.activities {

                activity.recordID = getCKRecordID(recordID: UUID(uuidString: activity.recordName))

                // set toSavePublished equal to toSave
                activity.setToSave(activity.toSave)
                activities.append(activity)
            }
            
            updateUI()
            
            return true
        }
        catch {
            localLogger.error("error:\(error.localizedDescription)")
            return false
        }
    }
    
    
    /// Write entire cache to JSON file in cache folder
    func write() -> Bool {
        
        guard let cacheURL = CacheURL(fileName: cacheFile, testMode: testMode) else { return false }
        
        localLogger.log("Writing cache to JSON file")

        do {
            let data = try JSONEncoder().encode(self)

            do {
                try data.write(to: cacheURL)

                return true
            }
            catch {
                localLogger.error("error \(error.localizedDescription)")
                return false
            }

        } catch {
            localLogger.error("Error enconding cache")
            return false
        }

    }

    
    /// On block completion copy temporary list to the main device list
    func blockFetchCompletion(ckRecordList: [CKRecord]) -> Void {
        
        if !self.dirty() {
            self.activities = ckRecordList.map( {ActivityRecord(fromCKRecord: $0, settingsManager: self.settingsManager)})
            _ = self.write()

            self.updateUI()
        }
    }
    
    
    private func refreshCache() {
        
        fetchRecordBlock(query: activityQuery(startDate: nil),
                         blockCompletionFunction: blockFetchCompletion,
                         resultsLimit: cacheSize,
                         qualityOfService: .userInitiated)
    }
  
    
    func fetchNextBlock() {
                
        let latestUIDate = UIRecordSet.last?.startDateLocal ?? nil
        localLogger.log("Fetch next block with start date \(String(describing: latestUIDate?.formatted()))")

        fetchRecordBlock(query: activityQuery(startDate: latestUIDate),
                         blockCompletionFunction: nextBlockCompletion,
                         resultsLimit: cacheSize,
                         qualityOfService: .userInitiated)
        
    }
    
    
    private func nextBlockCompletion(records : [CKRecord] ) -> Void {
        
        localLogger.log("Next block fetch completion")
        DispatchQueue.main.async {
            self.UIRecordSet += records.map( {ActivityRecord(fromCKRecord: $0, settingsManager: self.settingsManager)})
        }
    }
  
    
    func CKForceUpdate(activityCKRecord: CKRecord, completionFunction: @escaping (CKRecord?) -> Void) {
        
        forceUpdate(ckRecord: activityCKRecord, completionFunction: completionFunction)

    }
   
    
    func fetchRecord(recordID: CKRecord.ID,
                     completionFunction: @escaping (ActivityRecord) -> (),
                     completionFailureFunction: @escaping () -> ()) {

        self.localLogger.log("Fetching track file for record: \(recordID)")
        
        // check if this record already cached
        if let cachedRecord = fullActivityRecordCache.get(recordID: recordID) {
            self.localLogger.log("Required record already cached")
            completionFunction(cachedRecord)

            return
        }
        
        // TODO - check if record not saved yet!!!
        if let unsavedActivity = activities.filter({$0.recordID == recordID && $0.toSave}).first {
            self.localLogger.log("Required record not yet saved, so copying existing object")
            let unsavedRecord = ActivityRecord(fromActivityRecord: unsavedActivity,
                                               settingsManager: settingsManager)
            fullActivityRecordCache.add(activityRecord: unsavedRecord)
            completionFunction(unsavedRecord)

            return
        }

        fetchRecord(recordID: recordID,
                    completionFunction: { ckRecord in
            let record = ActivityRecord(fromCKRecord: ckRecord, settingsManager: self.settingsManager)
            self.fullActivityRecordCache.add(activityRecord: record)
            completionFunction(record) },
                    completionFailureFunction: completionFailureFunction)
        
    }
    

    func recordSaveCompletion(recordID: CKRecord.ID) -> Void {
        guard let savedActivityRecord = self.activities.filter({ $0.recordName == recordID.recordName }).first else {return}
        savedActivityRecord.deleteTrackRecord()
        savedActivityRecord.setToSave(false)
        
        _ = self.write()
    }
    
    func recordDeletionCompletion(recordID: CKRecord.ID) -> Void {
        removeFromCache(recordID: recordID)
    }
    
    func CKsaveAndDeleteRecord(recordsToSave: [CKRecord],
                               recordIDsToDelete: [CKRecord.ID]) {

        saveAndDeleteRecord(recordsToSave: recordsToSave,
                            recordIDsToDelete: recordIDsToDelete,
                            recordSaveSuccessCompletionFunction: recordSaveCompletion,
                            recordDeleteSuccessCompletionFunction: recordDeletionCompletion)

    }
    
    
    func registerNotifications(notificationManager: CloudKitNotificationManager) {
        notificationManager.registerNotificationFunctions(recordType: "Activity",
                                                          recordDeletionFunction: processRecordDeletedNotification,
                                                          recordChangeFunction: processRecordChangeNofification)
    }
    
    
    private func processRecordDeletedNotification(recordID: CKRecord.ID) {

        localLogger.log("Processing record deletion: \(recordID)")
        removeFromCache(recordID: recordID)
        removeFromUI(recordID: recordID)
        
    }


    private func processRecordChangeNofification(record: CKRecord) {

        let recordDesc: String = record["name"] ?? "" + " : " + (record["startDateLocal"] as? Date ?? Date(timeIntervalSince1970: 0)).formatted(Date.ISO8601FormatStyle())
        localLogger.log("Processing record change: \(recordDesc)")
        
        let activityRecord = ActivityRecord(fromCKRecord: record, settingsManager: settingsManager, fetchtrackData: false)
        
        changeCache(changedActivityRecord: activityRecord)
        changeUI(changedActivityRecord: activityRecord)
        
    }
    
    func fetchAllRecordIDs(recordCompletionFunction: @escaping (CKRecord.ID) -> ()) {
               
        let pred = NSPredicate(value: true)
        var minStartDate: Date? = nil
        var recordCount: Int = 0
        let sort = NSSortDescriptor(key: "startDateLocal", ascending: false)
        let query = CKQuery(recordType: "Activity", predicate: pred)
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
                self.localLogger.error( "Fetch failed for recordID \(recordID) : \(String(describing: error))")
                
                break
            }
        }
            
        operation.queryResultBlock = { result in

            switch result {
            case .success:

                self.localLogger.info("Record fetch successfully complete : record count \(recordCount) : min date \(minStartDate!.formatted(Date.ISO8601FormatStyle().dateSeparator(.dash)))")
                
                break
                    
            case .failure(let error):

                switch error {
                case CKError.accountTemporarilyUnavailable,
                    CKError.networkFailure,
                    CKError.networkUnavailable,
                    CKError.serviceUnavailable,
                    CKError.zoneBusy:
                    
                    self.localLogger.log("temporary refresh error")

                    
                default:
                    self.localLogger.error("permanent refresh error - not retrying")
                }
                self.localLogger.error( "Fetch failed \(String(describing: error))")
                break
            }

        }
        
        database.add(operation)

    }

}
