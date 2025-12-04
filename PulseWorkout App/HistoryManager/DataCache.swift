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
        try FileManager.default.createDirectory(at: cachePath.appendingPathComponent(ActivityImageType.mapSnapshot.rawValue),
                                                withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: cachePath.appendingPathComponent(ActivityImageType.altitudeImage.rawValue),
                                                withIntermediateDirectories: true)
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

func ImageCacheURL(fileName: String, imageType: ActivityImageType, testMode: Bool = false) -> URL? {

    guard let cachePath = getCacheDirectory(testMode: testMode) else { return nil }

    return cachePath.appendingPathComponent(imageType.rawValue).appendingPathComponent(fileName)
}


/// Delete content of cache directory and remove all sub-directories
func clearCache(testMode: Bool = false) {
    let fm = FileManager.default
    
    do {
        
        guard let baseCachePath = getCacheDirectory(testMode: testMode) else {return}
 
        let files = try fm.contentsOfDirectory(atPath: baseCachePath.path)

        // NOTE - this removes files AND whole subdirectories
        for file in files {
            let path = baseCachePath.appendingPathComponent(file)
            do {

                try FileManager.default.removeItem(at: path)

            } catch {
                print(error)
            }
        }

    } catch {
        print("Directory search failed! \(error)")
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
    
    
    // Get the full record from the cache, if not there fetch and add to the case then return it...
    func asyncGet(recordID: CKRecord.ID) async throws -> ActivityRecord {
        
        if let record = get(recordID: recordID) {
            return record
        }
        
        do {
            let ckRecord = try await CKFetchRecordOperation(recordID: recordID).asyncExecute()

            let fetchedActivityRecord = ActivityRecord(fromCKRecord: ckRecord, fetchtrackData: true)
            
            add(activityRecord: fetchedActivityRecord)
            
            return fetchedActivityRecord
            
        } catch let error {
            throw error
        }

    }

}

class DataCache: NSObject, Codable, ObservableObject {
    
    let settingsManager: SettingsManager = SettingsManager.shared
    let statisticsManager: StatisticsManager = StatisticsManager.shared
    var testMode: Bool = false
        

    // List of records shown in UI
    @Published var UIRecordSet: [ActivityRecord] = []


    // Activity record fetched and used in detail display
    let fullActivityRecordCache: FullActivityRecordCache = FullActivityRecordCache()
    
    // Cache for map snapshot images
    var imageCache: ImageCache!

       
    let cacheSize = 50
    let cacheFile = "activityCache.act"
    let localLogger = Logger(subsystem: "com.RMurray.PulseWorkout",
                             category: "dataCache")
    private var flushingCache: Bool = false
    private var activities: [ActivityRecord] = []
    private var refreshList: [ActivityRecord] = []
   
    // set CodingKeys to define which variables are stored to JSON file
    private enum CodingKeys: String, CodingKey {
        case activities
    }

    init(readCache: Bool = true, testMode: Bool = false) {

        super.init()
        self.testMode = testMode
        imageCache = ImageCache(dataCache: self)
                
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

    
    func refreshUI(qualityOfService: QualityOfService = .userInitiated) {
        
        if !dirty() {
            refreshCache(qualityOfService: qualityOfService)
        }
        else {
            flushCache(qualityOfService: qualityOfService)

            updateUI()
        }
        
    }
    
    
    /// Push changes in cache to cloudkit - activity saves & deletes + update statistics as a single transaction
    /// Before saving get a new copy of statistics from CK and play any changes in to it from dirty cache
    func flushCache(qualityOfService: QualityOfService = DEFAULT_CLOUDKIT_QOS) {
        
        // Only allow one flush operation to be in process.
        // If a second is called, it will not do anything, but the first
        // should notice the cache is dirty on completion so will flush again...
        if (dirty() && !flushingCache) {

            self.localLogger.info("Refreshing statistics")
            statisticsManager.refresh(onRefreshCompletionFunc: {

                if !self.flushingCache {
                    self.flushingCache = true

                    // Add changes back into refreshed statistics
                    for activityRecord in self.toBeSaved() {
                        self.statisticsManager.addActivityToStats(activity: activityRecord)
                    }
                    for activityRecord in self.toBeDeleted() {
                        self.statisticsManager.removeActivityFromStats(activity: activityRecord)
                    }
                    
                    self.localLogger.info("Flushing cache with records \(self.toBeSavedCKRecords())")
                
                    CKBlockSaveAndDeleteOperation(
                        recordsToSave: self.toBeSavedCKRecords() + self.statisticsManager.allCKRecords(),
                        recordIDsToDelete: self.toBeDeletedIDs(),
                        recordSaveSuccessCompletionFunction: self.recordSaveCompletion,
                        recordDeleteSuccessCompletionFunction: self.removeFromCache,
                        blockSuccessCompletion: {
                            self.flushingCache = false
                            _ = self.write()
                            // If new changes whilst flush then flush again!
                            if self.dirty() {
                                self.flushCache(qualityOfService: qualityOfService)
                            }
                        },
                        blockFailureCompletion: {self.flushingCache = false},
                        qualityOfService: qualityOfService).execute()
                }
            })
        }
    }
    
    
    /// Copy cache contents to User Interface list - trigger view update
    private func updateUI() {
        
        DispatchQueue.main.async { [self] in
            self.UIRecordSet = self.cache()
        }
        
    }
    

    
    func add(activityRecord: ActivityRecord, toBeSavedToCK: Bool = true) {
        
        activityRecord.setToSave(toBeSavedToCK)
        
        // Update if an existing record - detect by stravaId or recordId
        if let updateIndex = activities.firstIndex(where: {
            (($0.stravaId != nil) && ($0.stravaId == activityRecord.stravaId)) ||
            (($0.recordID != nil) && ($0.recordID == activityRecord.recordID))}) {
            
            // Update the record in the cache
            localLogger.info("Updating cache at index : \(updateIndex)")
            activities[updateIndex] = activityRecord
            
        }
        else {
            if let insertIndex = activities.firstIndex(where: {$0.startDateLocal < activityRecord.startDateLocal}) {

                localLogger.info("Inserting into cache at index : \(insertIndex)")
                activities.insert(activityRecord, at: insertIndex)
                
            } else {
                if toBeSavedToCK {
                    activities.append(activityRecord)
                }
            }
            statisticsManager.addActivityToStats(activity: activityRecord)
        }
        

        // Now see if UI record set needs to be updated / inserted
        if let updateIndex = UIRecordSet.firstIndex(where: {
            (($0.stravaId != nil) && ($0.stravaId == activityRecord.stravaId)) ||
            (($0.recordID != nil) && ($0.recordID == activityRecord.recordID))}) {
            
            // Update the UI Record Set
            localLogger.info("Updating UIRecordSet at index : \(updateIndex)")
            DispatchQueue.main.async {
                self.UIRecordSet[updateIndex] = activityRecord
            }

            
        } else {
            if let insertIndex = UIRecordSet.firstIndex(where: {$0.startDateLocal < activityRecord.startDateLocal}) {

                localLogger.info("Inserting into UIRecordSet at index : \(insertIndex)")
                DispatchQueue.main.async {
                    self.UIRecordSet.insert(activityRecord, at: insertIndex)
                }
                
            }
        }

        
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
    
    
    func delete(activityRecord: ActivityRecord) {
        
        var index: Int
        
        if let recordID = activityRecord.recordID {

            removeFromUI(recordID: recordID)
            
            index = cachedIndex(recordID: recordID) ?? activities.endIndex
            
            if index == activities.endIndex {
                // Record is not in cache, so append to cache
                activities.append(activityRecord)
            }
        
            // Record is in cache, mark to delete in cahce and then flush cache
            activities[index].toDelete = true
            activities[index].deleteTrackRecord()
            statisticsManager.removeActivityFromStats(activity: activityRecord)
            
            localLogger.debug("DELETED OK :\(index) \(recordID.recordName)")
            _ = write()
            
            flushCache()
            
        }
    }
    
    
    /// Remove item from cache - call once deleted from cloudkit
    func removeFromCache(recordID: CKRecord.ID) {
        
        guard let index = activities.firstIndex(where: { $0.recordName == recordID.recordName }) else {
            return
        }

        activities.remove(at: index)
        
        imageCache.remove(recordName: recordID.recordName)

        
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

                activity.recordID = CloudKitOperation().getCKRecordID(recordID: UUID(uuidString: activity.recordName))

                // set toSavePublished equal to toSave
                activity.setToSave(activity.toSave)
                activities.append(activity)
            }
            
            updateUI()
            
            return true
        }
        catch {
            localLogger.error("cache read error:\(error)")
            return false
        }
    }
    
    
    /// Write entire cache to JSON file in cache folder
    func write() -> Bool {
        
        guard let cacheURL = CacheURL(fileName: cacheFile, testMode: testMode) else { return false }
        
        // If cache has no unsaved activities then reset size to target cache size
        if !dirty() {
            while activities.count > cacheSize {
                activities.removeLast()
            }
        }
        
        localLogger.log("Writing activities cache to JSON file")

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
    func refreshCacheCompletion(ckRecordList: [CKRecord]) -> Void {
        
        if !self.dirty() {
            self.activities = ckRecordList.map( {ActivityRecord(fromCKRecord: $0, fetchtrackData: false)})
            _ = self.write()

            self.updateUI()
            
            statisticsManager.refresh()
        }
    }
    
    
    private func refreshCache(qualityOfService: QualityOfService = .userInitiated) {
        
        CKActivityQueryOperation(startDate: nil,
                                 blockCompletionFunction: refreshCacheCompletion,
                                 resultsLimit: cacheSize,
                                 qualityOfService: qualityOfService).execute()
    }
  
    
    func getLatestUIDate() -> Date? {
        return UIRecordSet.last?.startDateLocal ?? nil
    }
    
    
    func addRecordsToUI(records : [CKRecord] ) -> Void {
        DispatchQueue.main.async {
            self.UIRecordSet += records.map( {ActivityRecord(fromCKRecord: $0, fetchtrackData: false)})
        }
    }
    
    func isFetchComplete(records : [CKRecord] ) -> Bool {
     
        if records.count == cacheSize {
            return false
        }
        
        return true
        
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
            let unsavedRecord = ActivityRecord(fromActivityRecord: unsavedActivity)
            fullActivityRecordCache.add(activityRecord: unsavedRecord)
            completionFunction(unsavedRecord)

            return
        }
        
        CKFetchRecordOperation(recordID: recordID,
                               completionFunction: { ckRecord in
            let record = ActivityRecord(fromCKRecord: ckRecord, fetchtrackData: true)
            self.fullActivityRecordCache.add(activityRecord: record)
            completionFunction(record) },
                               completionFailureFunction: completionFailureFunction).execute()
        
    }
    

    func recordSaveCompletion(recordID: CKRecord.ID) -> Void {
        guard let savedActivityRecord = self.activities.filter({ $0.recordName == recordID.recordName }).first else {return}
        savedActivityRecord.deleteTrackRecord()
        savedActivityRecord.setToSave(false)
        
#if os(iOS)
        if savedActivityRecord.stravaSaveStatus == StravaSaveStatus.toSave.rawValue {
            savedActivityRecord.saveToStrava()
        }
#endif
        
//        _ = self.write()
    }
    

    
    
    func registerNotifications(notificationManager: CloudKitNotificationManager) {
        notificationManager.registerNotificationFunctions(recordType: "Activity",
                                                          recordDeletionFunction: processRecordDeletedNotification,
                                                          recordChangeFunction: processRecordChangeNofification)
    }
    
    
    private func processRecordDeletedNotification(recordID: CKRecord.ID) {

        localLogger.log("Processing record deletion: \(recordID)")
        removeFromCache(recordID: recordID)
        _ = write()
        removeFromUI(recordID: recordID)
        
        statisticsManager.refresh()
        
    }


    private func processRecordChangeNofification(record: CKRecord) {

        var activityRecord: ActivityRecord
        
        let recordDesc: String = record["name"] ?? "" + " : " + (record["startDateLocal"] as? Date ?? Date(timeIntervalSince1970: 0)).formatted(Date.ISO8601FormatStyle())
        localLogger.log("Processing record change: \(recordDesc)")
        
        activityRecord = ActivityRecord(fromCKRecord: record, fetchtrackData: false)
        
        #if os(iOS)
        if activityRecord.stravaSaveStatus == StravaSaveStatus.toSave.rawValue {
            activityRecord = ActivityRecord(fromCKRecord: record, fetchtrackData: true)
            activityRecord.saveToStrava()
        }
        #endif
        
        changeCache(changedActivityRecord: activityRecord)
        changeUI(changedActivityRecord: activityRecord)
        
        statisticsManager.refresh()
        
    }

}
