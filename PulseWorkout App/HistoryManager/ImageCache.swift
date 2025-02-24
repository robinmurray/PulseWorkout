//
//  ImageCache.swift
//  PulseWorkout
//
//  Created by Robin Murray on 23/12/2024.
//

import Foundation
import os
import UIKit




class ImageCache: NSObject {

    var dataCache: DataCache
    var testMode = false
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "imageCache")
    
    init(dataCache: DataCache, testMode: Bool = false) {
        self.dataCache = dataCache
        self.testMode = testMode
    }
    
    
    /// Add item for record to cache, so long as record is in main record cache
    /// OR - forceWrite set to true  - then will write anyway (caller must arrange deletion!
    /// returns URL of written file
    func add(record: ActivityRecord,
             image: Data,
             imageType: ActivityImageType,
             forceWrite: Bool = false) -> URL? {
        
        if (dataCache.isCached(recordName: record.recordName)) || forceWrite {
            
            guard let imageURL = imageURL(record: record, imageType: imageType) else { return nil }
            
            do {
                try image.write(to: imageURL)
                return imageURL

            } catch let error {
                logger.error("Error writing to image cache \(error.localizedDescription)")
            }
        }
        return nil
    }
    

    /// Remove item for record from cache for all image types, if record is not in cache
    func remove(record: ActivityRecord) {
        
        remove(recordName: record.recordName)
    }
    
    /// Remove item for record from cache for all image types, if record is not in cache - by recordName
    func remove(recordName: String) {
        
        if !dataCache.isCached(recordName: recordName) {
            for imageType in ActivityImageType.allCases  {
                guard let imageURL = imageURL(recordName: recordName, imageType: imageType) else { return }
                
                do {
                    try FileManager.default.removeItem(at: imageURL)
                    logger.info("Removed item from image cache \(imageURL)")
                    
                } catch let error {
                    logger.info("Unable to remove item from image cache \(imageURL) : \(error.localizedDescription)")
                }
            }
        }
    }

    
    
    /// Return image fom cache or nil if not cached
    func getImage(record: ActivityRecord, imageType: ActivityImageType) -> UIImage? {
        
        guard let thisURL = imageURL(record: record, imageType: imageType) else {return nil}
        
        if let data = try? Data(contentsOf: thisURL ) {
            return UIImage(data: data)
        }
        logger.info("Failed to get image from cache for \(record.name)")
        return nil
    }
    
    /// Remove items from image cache that do not belong to items in main record cache
    private func clean() {
        let fm = FileManager.default
 
        for imageType in ActivityImageType.allCases  {
            do {
                guard let baseCache = getCacheDirectory(testMode: testMode) else { return }
                let baseImageCache = baseCache.appendingPathComponent(imageType.rawValue)
                        
                let files = try fm.contentsOfDirectory(atPath: baseImageCache.path)
                for file in files {
                    let path = baseImageCache.appendingPathComponent(file)
                    let recordName = recordName(imagePath: path)
                    if !dataCache.isCached(recordName: recordName) {
                        do {
                            try FileManager.default.removeItem(at: path)

                        } catch let error {
                            print("Cleaning cache error \(error.localizedDescription)")
                        }
                    }
                    
                }
            } catch {
                print("Directory search failed!")
                // failed to read directory – bad permissions, perhaps?
            }
        }
        
    }
    
    /// Get expected URL for cached image for record
    private func imageURL(record: ActivityRecord, imageType: ActivityImageType) -> URL? {
        
        return imageURL(recordName: record.recordName, imageType: imageType)

    }
    
    /// Get expected URL for cached image for record from record name
    private func imageURL(recordName: String, imageType: ActivityImageType) -> URL? {
        
        guard let baseURL = ImageCacheURL(fileName: recordName,
                                          imageType: imageType,
                                          testMode: testMode) else { return nil }
                        
        return baseURL.appendingPathExtension("png")
    }
    
    /// Get expected record name from file name
    private func recordName(imagePath: URL) -> String {
        
        return URL(string: imagePath.lastPathComponent)!.deletingPathExtension().absoluteString
        
    }
    
}

