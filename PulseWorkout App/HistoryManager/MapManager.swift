//
//  MapManager.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 06/11/2024.
//

import Foundation
import MapKit
import CloudKit
import HealthKit


extension ActivityRecord {

    func saveMapSnapshot() {
        
        // NOTE - if record not yet saved then shouldn't do update!
        
        guard let dc = self.dataCache else {
            logger.error("dataCache not set")
            return
        }
        
        guard
            let image = mapSnapshotImage,

            // FIX - put URL in json ??
            let data = image.jpegData(compressionQuality: 0.5)
        else { return }
        
        // Add image to image cache if record is in cache
        dc.imageCache.add(record: self, image: data)
        
        mapSnapshotFileURL = getCacheDirectory()?.appendingPathComponent(baseFileName + ".jpg")

        do {
            try data.write(to: mapSnapshotFileURL!)
                        
            let asset = CKAsset(fileURL: mapSnapshotFileURL!)
            // FIX!!! - should be able to align with other CKRecord stuff!!!
            let activityCKRecord = CKRecord(recordType: recordType, recordID: recordID)
            activityCKRecord["mapSnapshot"] = asset

            // Only update if already saved! - should get picked up by record save
            // if not then will update saved record on next display...
            if !toSave {
                dc.CKForceUpdate(activityCKRecord: activityCKRecord,
                                 completionFunction: saveSnapshotCompletion)
            }
            
            
        } catch let error {
            logger.error("Error creating snapshot asset \(error)")
        }
    }
    
    /// Completion function for saving snapshot
    /// sets snapshotURL if succesful and deletes temporary .jpg file
    func saveSnapshotCompletion(activityCKRecord: CKRecord?) {
        
        guard let ar = activityCKRecord else {
            deleteSnapshotFile()
            return
        }
        
        guard let snapshotAsset = ar["mapSnapshot"] as CKAsset? else { return }

//        mapSnapshotURL = snapshotAsset.fileURL
        logger.log("Snapshot URL set")
        deleteSnapshotFile()
        
        if let dc = dataCache {
            _ = dc.write()
        }

    }
    
    /// Remove temporary .jpg file
    private func deleteSnapshotFile() {

        guard let snapshotFile = mapSnapshotFileURL else { return }

        do {
            try FileManager.default.removeItem(at: snapshotFile)
                logger.debug("jpg has been deleted")
        } catch {
            logger.error("error \(error)")
        }
    }
    
    func getMapSnapshot(dataCache: DataCache) {
        
        if !(hasLocationData) {
            return
        }
        
        self.dataCache = dataCache

        // check if snapshot already exists
        if mapSnapshotImage != nil {
            logger.info("Snapshot already exists \(self.name) : \(self.startDateLocal)")
            return
        }
        
        if let image = dataCache.imageCache.getImage(record: self) {
            logger.info("Retrieved image from image cache")
            mapSnapshotImage = image
            return
        }
        
        if mapSnapshotURL != nil {
            logger.info("Getting image from cached URL for \(self.name) : \(self.startDateLocal)")
            if let data = try? Data(contentsOf: mapSnapshotURL! ),
               let image = UIImage(data: data) {
                mapSnapshotImage = image
                logger.info("got image from cached URL for \(self.name) : \(self.startDateLocal) with URL \(self.mapSnapshotURL!.absoluteString)")
                dataCache.imageCache.add(record: self, image: data)
                return
            }
            logger.info("Failed to get image from cached URL for \(self.name) : \(self.startDateLocal) with URL \(self.mapSnapshotURL!.absoluteString)")
            
        }
        // check if map snapshot already created and available as URL from cloudkit
        if mapSnapshotAsset != nil {
            logger.info("Trying to get image from existing mapSnapshotAsset for \(self.name) : \(self.startDateLocal)")
            if let mapSnapshotURL = mapSnapshotAsset?.fileURL,
               let data = try? Data(contentsOf: mapSnapshotURL ),
               let image = UIImage(data: data) {
                logger.info("Got image from existing mapSnapshotAsset for \(self.name) : \(self.startDateLocal)")
                mapSnapshotImage = image
                dataCache.imageCache.add(record: self, image: data)
                return
            }
        }
        
        // if trackpoints already exist then create snapshot, else fetch trackpoints and then create snapshot
        if trackPoints.count > 0 {
            logger.info("Building image from existing trackpoints for \(self.name) : \(self.startDateLocal)")
            setMapSnapshot(fromActivityRecord: self)
        }
        else {
            logger.info("fetching track record for snapshot for record \(self.name) : \(self.startDateLocal)")
            dataCache.fetchRecord(recordID: recordID,
                                  completionFunction: self.setMapSnapshot,
                                  completionFailureFunction: self.buildSnapshotFailure)
        }
        
    }
    
    /// Completion failure function for fetching record for snapshot
    func buildSnapshotFailure() -> () {
        logger.error("Failed to fetch record for snapshot")
    }
    
    func getRouteCoordinates() -> [CLLocationCoordinate2D] {
        
        // Create list of non-null locations
        return self.trackPoints.filter(
            {$0.latitude != nil && $0.longitude != nil}).map(
                {CLLocationCoordinate2D(latitude: $0.latitude!, longitude: $0.longitude!)})

    }
    
    func setMapSnapshot (fromActivityRecord: ActivityRecord) {

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

                   self.mapSnapshotImage = img

                   self.saveMapSnapshot()

               } else if let error = error {
                   self.logger.error("Error creating snapshot \(error.localizedDescription)")
               }
            }
        }

    }
    
    
}

