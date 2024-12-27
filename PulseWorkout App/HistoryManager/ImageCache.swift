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
    func add(record: ActivityRecord, image: Data) {
        
        if dataCache.isCached(recordName: record.recordName) {
            
            guard let imageURL = imageURL(record: record) else { return }
            
            do {
                try image.write(to: imageURL)

            } catch let error {
                logger.error("Error writing to image cache \(error.localizedDescription)")
            }
        }
    }
    
    
    /// Remove item for record from cache
    func remove(record: ActivityRecord) {
        
        guard let imageURL = imageURL(record: record) else { return }
        
        do {
            try FileManager.default.removeItem(at: imageURL)

        } catch let error {
            logger.info("Unable to remove item from image cache \(imageURL) : \(error.localizedDescription)")
        }
    }
    
    
    /// Return image fom cache or nil if not cached
    func getImage(record: ActivityRecord) -> UIImage? {
        
        guard let thisURL = imageURL(record: record) else {return nil}
        
        if let data = try? Data(contentsOf: thisURL ) {
            return UIImage(data: data)
        }
        logger.info("Failed to get image from cache for \(record.name)")
        return nil
    }
    
    /// Remove items from image cache that do not belong to items in main record cache
    private func clean() {
        let fm = FileManager.default
        
        do {
            let files = try fm.contentsOfDirectory(atPath: getCacheDirectory(testMode: testMode)!.path)
            let jpgFiles = files.filter{ URL(string: $0)!.pathExtension == "json" }
            
            for file in jpgFiles {
                let path = getCacheDirectory(testMode: testMode)!.appendingPathComponent(file)
                let recordName = recordName(imagePath: path)
                if dataCache.isCached(recordName: recordName) {
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
    
    /// Get expected URL for cached image for record
    private func imageURL(record: ActivityRecord) -> URL? {
        
        let URL = CacheURL(fileName: record.recordName, testMode: testMode)?.appendingPathExtension("jpg")
        
        return URL
    }
    
    /// Get expected record name from file name
    private func recordName(imagePath: URL) -> String {
        
        return URL(string: imagePath.lastPathComponent)!.deletingPathExtension().absoluteString
        
    }
    
}

