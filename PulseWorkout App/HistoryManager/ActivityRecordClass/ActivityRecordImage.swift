//
//  ActivityRecordImage.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 22/02/2025.
//

import Foundation
import MapKit
import CloudKit
import HealthKit
import os
import SwiftUI

enum ActivityImageType: String, CaseIterable {
    case mapSnapshot = "mapSnapshot"
    case altitudeImage = "altitudeImage"
    
}

/// Class for creating, storing and retrieving images build from Activity data
class ActivityRecordImage: NSObject {
    
    var activityRecord: ActivityRecord
    var activityImageType: ActivityImageType
    var dataCache: DataCache = DataCache.shared
    var thisImage: UIImage?
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "activityRecordImage")
    
    init(activityRecord: ActivityRecord, activityImageType: ActivityImageType) {
        self.activityRecord = activityRecord
        self.activityImageType = activityImageType
    }
    
    /// Save the activity record image, to cloudkit and cache (if record is cached)
    func save() {
        
        // NOTE - if record not yet saved then shouldn't do update!
                
        guard
            let image = thisImage,
            
                // FIX - put URL in json ??
            let data = image.pngData()
        else { return }
        
        // Force add image to image cache - delete on completion if record is not in cache!
        if let fileURL = dataCache.imageCache.add(record: activityRecord,
                                                  image: data,
                                                  imageType: activityImageType,
                                                  forceWrite: true) {
            
            do {
                try data.write(to: fileURL)
                
                let asset = CKAsset(fileURL: fileURL)
                // FIX!!! - should be able to align with other CKRecord stuff!!!
                let activityCKRecord = CKRecord(recordType: activityRecord.recordType,
                                                recordID: activityRecord.recordID)
                activityCKRecord[activityImageType.rawValue] = asset
                
                // Only update if already saved! - should get picked up by record save
                // if not then will update saved record on next display...
                if !activityRecord.toSave {

                    CKForceUpdateOperation(ckRecord: activityCKRecord,
                                           completionFunction: saveCompletion).execute()
                }
                
                
            } catch let error {
                logger.error("Error creating snapshot asset \(error)")
            }
        }
        
    }
    

    /// Remove file from image cache if activityRecord is not cached
    func saveCompletion(CKRecordID: CKRecord.ID?) {
        
        dataCache.imageCache.remove(record: activityRecord)
        
        #if os(iOS)
        if activityRecord.stravaSaveStatus == StravaSaveStatus.toSave.rawValue {
            activityRecord.saveToStrava()
        }
        #endif

    }
    
    
    func get(image: inout UIImage?, url: inout URL?, asset: CKAsset?, buildFunc: @escaping (ActivityRecord) -> Void) {
        
        if !(activityRecord.hasLocationData) {
            return
        }
        
        // check if snapshot already exists
        if image != nil {
            logger.info("Snapshot already exists \(self.activityRecord.name) : \(self.activityRecord.startDateLocal)")
            return
        }
        
        if let imageFromCache = dataCache.imageCache.getImage(record: activityRecord, imageType: activityImageType) {
            logger.info("Retrieved image from image cache")
            image = imageFromCache
            return
        }
        
        if (url == nil) && (asset != nil) {
            logger.info("Trying to get image from existing asset for \(self.activityRecord.name) : \(self.activityRecord.startDateLocal)")

            url = asset!.fileURL
        }
        
        if url != nil {
            let thisURL = url!
            logger.info("Getting image from URL for \(self.activityRecord.name) : \(self.activityRecord.startDateLocal)")
            if let data = try? Data(contentsOf: url! ),
               let imageFromURL = UIImage(data: data) {
                image = imageFromURL
                logger.info("got image from URL for \(self.activityRecord.name) : \(self.activityRecord.startDateLocal) with URL \(thisURL.absoluteString)")
                _ = dataCache.imageCache.add(record: activityRecord,
                                             image: data,
                                             imageType: activityImageType)
                return
            }
            logger.info("Failed to get image from URL for \(self.activityRecord.name) : \(self.activityRecord.startDateLocal) with URL \(thisURL.absoluteString)")
            
        }
        
        
        // if trackpoints already exist then create snapshot, else fetch trackpoints and then create snapshot
        if activityRecord.trackPoints.count > 0 {
            logger.info("Building image from existing trackpoints for \(self.activityRecord.name) : \(self.activityRecord.startDateLocal)")
            buildFunc(activityRecord)
        }
        else {
            logger.info("fetching track record for snapshot for record \(self.activityRecord.name) : \(self.activityRecord.startDateLocal)")
            dataCache.fetchRecord(recordID: activityRecord.recordID,
                                  completionFunction: buildFunc,
                                  completionFailureFunction: self.buildFailure)
        }
        
    }
    
    
    /// Completion failure function for fetching record for snapshot
    func buildFailure() -> () {
        logger.error("Failed to fetch record to buildimage")
    }
    
}


#if os(iOS)
/// Concrete sub-class of ActivityRecordImage to manage map snapshot image
class ActivityRecordSnapshotImage: ActivityRecordImage {
    
    init(activityRecord: ActivityRecord) {
        
        super.init(activityRecord: activityRecord, activityImageType: .mapSnapshot)
    }
    
    func get(image: inout UIImage?, url: inout URL?, asset: CKAsset?) {
        super.get(image: &image, url: &url, asset: asset, buildFunc: build)
    }
    
    func build(fromActivityRecord: ActivityRecord) {

        var routeCoordinates: [CLLocationCoordinate2D] = []

        let options: MKMapSnapshotter.Options = .init()

        routeCoordinates = fromActivityRecord.getRouteCoordinates()
        
        if routeCoordinates.count > 0 {
            let latitudes = routeCoordinates.map({$0.latitude})
            let longitudes = routeCoordinates.map({$0.longitude})
            let midLatitude = (latitudes.max()! + latitudes.min()!) / 2
            let midLongitude = (longitudes.max()! + longitudes.min()!) / 2
            let routeCenter = CLLocationCoordinate2D(latitude: midLatitude,
                                                      longitude: midLongitude)
            let latitudeDelta = latitudes.max()! - latitudes.min()!
            let longitudeDelta = longitudes.max()! - longitudes.min()!
            
            options.region = MKCoordinateRegion(center: routeCenter,
                                                span: MKCoordinateSpan(latitudeDelta: latitudeDelta,  longitudeDelta: longitudeDelta))
            options.size = CGSize(width: 300, height: 150)
            options.mapType = .standard
            options.showsBuildings = true
            
            let snapshotter = MKMapSnapshotter(options: options)
            
            snapshotter.start { snapshot, error in
               if let snapshot = snapshot {
                   self.logger.info("Snapshot created!")
                   let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 150))

                      let img = renderer.image { context in
                          snapshot.image.draw(at: CGPoint(x:0, y:0))
                          var prevPoint: CGPoint? = nil
                          
                          context.cgContext.setLineWidth(1.0)
                          context.cgContext.setStrokeColor(UIColor.red.cgColor)
                          
                          for coordinate in routeCoordinates {
                              let point = snapshot.point(for: coordinate)
                              
                              if prevPoint != nil {
                                  context.cgContext.addLine(to: point)
                              } else {
                                  context.cgContext.move(to: point)
                              }
                              prevPoint = point
                          }
                          context.cgContext.drawPath(using: .stroke)
                      }

                   self.thisImage = img

                   self.activityRecord.mapSnapshotImage = self.thisImage
                   
                   self.save()

               } else if let error = error {
                   self.logger.error("Error creating snapshot \(error.localizedDescription)")
               }
            }
        }

    }

    
}
#endif

/// Concrete sub-class of ActivityRecordImage to manage altitude image
class ActivityRecordAltitudeImage: ActivityRecordImage {
    
    init(activityRecord: ActivityRecord) {
        
        super.init(activityRecord: activityRecord, activityImageType: .altitudeImage)
    }
    
    func get(image: inout UIImage?, url: inout URL?, asset: CKAsset?) {
        super.get(image: &image, url: &url, asset: asset, buildFunc: build)
    }
    
    /// Async function to build and save image
    func build(fromactivityRecord: ActivityRecord) {

        self.logger.debug("In build for ActivityRecordAltitudeImage")
        if (fromactivityRecord.hasLocationData) && (fromactivityRecord.trackPoints.count > 0) {
            let altitudeData = fromactivityRecord.trackPoints.filter( {($0.distanceMeters != nil) && ($0.altitudeMeters != nil) })
                .map( { AltitudeData(distance: $0.distanceMeters!,
                                     altitude: $0.altitudeMeters!) })
            
            DispatchQueue.main.async {
                let renderer = ImageRenderer(content: AltitudeChartImage(altitudeArray: altitudeData))
                
                self.thisImage = renderer.uiImage
                
                self.activityRecord.altitudeImage = self.thisImage
                
                // Save image to cache and to cloudkit
                self.save()
            }

        }
    }
}
