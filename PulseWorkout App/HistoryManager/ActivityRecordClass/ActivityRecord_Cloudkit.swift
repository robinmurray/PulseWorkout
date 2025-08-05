//
//  ActivityRecord_Cloudkit.swift
//  PulseWorkout
//
//  Created by Robin Murray on 26/02/2025.
//

import Foundation
import CloudKit


/// Extension for Saving / Receiving Activity Record to / from Cloudkit
extension ActivityRecord {
    
    func asCKRecord(addTrackData: Bool = true) -> CKRecord {
// !!        recordID = CKRecord.ID()
        let activityRecord = CKRecord(recordType: recordType, recordID: recordID)
        activityRecord["name"] = name as CKRecordValue
        activityRecord["stravaType"] = stravaType as CKRecordValue
        activityRecord["workoutTypeId"] = workoutTypeId as CKRecordValue
        activityRecord["workoutLocationId"] = workoutLocationId as CKRecordValue

//        activityRecord["sportType"] = sportType as CKRecordValue
        activityRecord["startDateLocal"] = startDateLocal as CKRecordValue
        activityRecord["startDate"] = startDate as CKRecordValue
        activityRecord["timeZone"] = timeZone.identifier as CKRecordValue
        activityRecord["GMTOffset"] = GMTOffset as CKRecordValue
        
        activityRecord["elapsedTime"] = (round(elapsedTime * 10) / 10) as CKRecordValue
        activityRecord["pausedTime"] = (round(pausedTime * 10) / 10) as CKRecordValue
        activityRecord["movingTime"] = (round(movingTime * 10) / 10) as CKRecordValue
        activityRecord["activityDescription"] = activityDescription as CKRecordValue
        activityRecord["distance"] = (round(distanceMeters * 10) / 10) as CKRecordValue

        activityRecord["averageHeartRate"] = (round(averageHeartRate * 10) / 10) as CKRecordValue
        activityRecord["averageCadence"] = averageCadence as CKRecordValue
        activityRecord["averagePower"] = averagePower as CKRecordValue
        activityRecord["averageSpeed"] = (round(averageSpeed * 1000) / 1000) as CKRecordValue
        activityRecord["maxHeartRate"] = maxHeartRate as CKRecordValue
        activityRecord["maxCadence"] = maxCadence as CKRecordValue
        activityRecord["maxPower"] = maxPower as CKRecordValue
        activityRecord["maxSpeed"] = (round(maxSpeed * 1000) / 1000) as CKRecordValue

        activityRecord["activeEnergy"] = (round(activeEnergy * 10) / 10) as CKRecordValue

        activityRecord["totalAscent"] = round(totalAscent ?? 0) as CKRecordValue
        activityRecord["totalDescent"] = round(totalDescent ?? 0) as CKRecordValue

        activityRecord["timeOverHiAlarm"] = timeOverHiAlarm as CKRecordValue
        activityRecord["timeUnderLoAlarm"] = timeUnderLoAlarm as CKRecordValue
        if hiHRLimit != nil {
            activityRecord["hiHRLimit"] = hiHRLimit! as CKRecordValue
        }
        if loHRLimit != nil {
            activityRecord["loHRLimit"] = loHRLimit! as CKRecordValue
        }
        activityRecord["stravaSaveStatus"] = stravaSaveStatus as CKRecordValue
        activityRecord["stravaId"] = stravaId as CKRecordValue?
        activityRecord["trackPointGap"] = trackPointGap as CKRecordValue

        activityRecord["TSS"] = TSS as CKRecordValue?
        activityRecord["FTP"] = FTP as CKRecordValue?
        activityRecord["powerZoneLimits"] = powerZoneLimits as CKRecordValue
        activityRecord["TSSbyPowerZone"] = TSSbyPowerZone as CKRecordValue
        activityRecord["movingTimebyPowerZone"] = movingTimebyPowerZone as CKRecordValue
        
        activityRecord["thesholdHR"] = thesholdHR
        activityRecord["estimatedTSSbyHR"] = estimatedTSSbyHR
        activityRecord["HRZoneLimits"] = HRZoneLimits
        activityRecord["TSSEstimatebyHRZone"] = TSSEstimatebyHRZone
        activityRecord["movingTimebyHRZone"] = movingTimebyHRZone
        
        activityRecord["hasLocationData"] = hasLocationData
        activityRecord["hasHRData"] = hasHRData
        activityRecord["hasPowerData"] = hasPowerData
        
        activityRecord["loAltitudeMeters"] = (round((loAltitudeMeters ?? 0) * 10) / 10) as CKRecordValue?
        activityRecord["hiAltitudeMeters"] = (round((hiAltitudeMeters ?? 0) * 10) / 10) as CKRecordValue?
        
        activityRecord["averageSegmentSize"] = averageSegmentSize as CKRecordValue?
        activityRecord["HRSegmentAverages"] = HRSegmentAverages
        activityRecord["powerSegmentAverages"] = powerSegmentAverages
        activityRecord["cadenceSegmentAverages"] = cadenceSegmentAverages
        
        if addTrackData {
            if saveTrackRecord() {
                logger.debug("creating tcx asset!")
                guard let tFile = tcxFileName else { return activityRecord }
                guard let tURL = CacheURL(fileName: tFile) else { return activityRecord }
                activityRecord["tcx"] = CKAsset(fileURL: tURL)
            }
        }


        return activityRecord

    }
    
    func asMinimalUpdateCKRecord() -> CKRecord {
        let activityRecord = CKRecord(recordType: recordType, recordID: recordID)
        activityRecord["stravaType"] = stravaType as CKRecordValue
        activityRecord["name"] = name as CKRecordValue

        activityRecord["activityDescription"] = activityDescription as CKRecordValue
        activityRecord["totalAscent"] = round(totalAscent ?? 0) as CKRecordValue
        activityRecord["stravaId"] = stravaId as CKRecordValue?

        return activityRecord

    }
    
    func fromCKRecord(activityRecord: CKRecord, fetchtrackData: Bool = true) {
        
        recordID = activityRecord.recordID
        recordName = recordID.recordName
        name = activityRecord["name"] ?? "" as String
        stravaType = activityRecord["stravaType"] ?? "Ride" as String
        workoutTypeId = activityRecord["workoutTypeId"] ?? 1 as UInt
        workoutLocationId = activityRecord["workoutLocationId"] ?? 1 as Int
//        sportType = activityRecord["sportType"] ?? "" as String
        startDateLocal = activityRecord["startDateLocal"] ?? Date() as Date
        startDate = activityRecord["startDate"] ?? Date() as Date
        timeZone = TimeZone(identifier: (activityRecord["timeZone"] ?? "GMT")) ?? TimeZone(identifier: "GMT")!
        GMTOffset = activityRecord["GMTOffset"] ?? 0 as Int
        elapsedTime = activityRecord["elapsedTime"] ?? 0 as Double
        pausedTime = activityRecord["pausedTime"] ?? 0 as Double
        movingTime = activityRecord["movingTime"] ?? 0 as Double
        activityDescription = activityRecord["activityDescription"] ?? "" as String
        distanceMeters = activityRecord["distance"] ?? 0 as Double
        totalAscent = activityRecord["totalAscent"] ?? 0 as Double
        totalDescent = activityRecord["totalDescent"] ?? 0 as Double

        averageHeartRate = activityRecord["averageHeartRate"] ?? 0 as Double
        averageCadence = activityRecord["averageCadence"] ?? 0 as Int
        averagePower = activityRecord["averagePower"] ?? 0 as Int
        averageSpeed = activityRecord["averageSpeed"] ?? 0 as Double
        maxHeartRate = activityRecord["maxHeartRate"] ?? 0 as Double
        maxCadence = activityRecord["maxCadence"] ?? 0 as Int
        maxPower = activityRecord["maxPower"] ?? 0 as Int
        maxSpeed = activityRecord["maxSpeed"] ?? 0 as Double
        activeEnergy = activityRecord["activeEnergy"] ?? 0 as Double
        timeOverHiAlarm = activityRecord["timeOverHiAlarm"] ?? 0 as Double
        timeUnderLoAlarm = activityRecord["timeUnderLoAlarm"] ?? 0 as Double
        hiHRLimit = activityRecord["hiHRLimit"] as Int?
        loHRLimit = activityRecord["loHRLimit"] as Int?

        stravaSaveStatus = (activityRecord["stravaSaveStatus"] ?? StravaSaveStatus.notSaved.rawValue) as Int
        stravaId = activityRecord["stravaId"] as Int?
        trackPointGap = activityRecord["trackPointGap"] ?? ACTIVITY_RECORDING_INTERVAL as Int
        
        TSS = activityRecord["TSS"] as Double?
        FTP = activityRecord["FTP"] as Int?
        powerZoneLimits = (activityRecord["powerZoneLimits"] ?? []) as [Int]
        TSSbyPowerZone = (activityRecord["TSSbyPowerZone"] ?? []) as [Double]
        movingTimebyPowerZone = (activityRecord["movingTimebyPowerZone"] ?? []) as [Double]
        
        thesholdHR = activityRecord["thesholdHR"] as Int?
        estimatedTSSbyHR = activityRecord["estimatedTSSbyHR"] as Double?
        HRZoneLimits = (activityRecord["HRZoneLimits"] ?? []) as [Int]
        TSSEstimatebyHRZone = (activityRecord["TSSEstimatebyHRZone"] ?? []) as [Double]
        movingTimebyHRZone = (activityRecord["movingTimebyHRZone"] ?? []) as [Double]
        
        hasLocationData = (activityRecord["hasLocationData"] ?? true) as Bool
        hasHRData = (activityRecord["hasHRData"] ?? true) as Bool
        hasPowerData = (activityRecord["hasPowerData"] ?? true) as Bool
        
        loAltitudeMeters = activityRecord["loAltitudeMeters"] as Double?
        hiAltitudeMeters = activityRecord["hiAltitudeMeters"] as Double?
   
        averageSegmentSize = activityRecord["averageSegmentSize"] as Int?
        HRSegmentAverages = (activityRecord["HRSegmentAverages"] ?? []) as [Int]
        powerSegmentAverages = (activityRecord["powerSegmentAverages"] ?? []) as [Int]
        cadenceSegmentAverages = (activityRecord["cadenceSegmentAverages"] ?? []) as [Int]
        
        mapSnapshotAsset = activityRecord["mapSnapshot"] as CKAsset?
        if mapSnapshotAsset != nil {
            mapSnapshotURL = mapSnapshotAsset!.fileURL
        }

        altitudeImageAsset = activityRecord["altitudeImage"] as CKAsset?
        if altitudeImageAsset != nil {
            altitudeImageURL = altitudeImageAsset!.fileURL
        }
        
        setToSave(false)
        toDelete = false
        tcxFileName = baseFileName + ".gz"
        JSONFileName = baseFileName + ".json"
        
        if fetchtrackData {
            if activityRecord["tcx"] != nil {
                self.logger.info("Parsing track data")
                let asset = activityRecord["tcx"]! as CKAsset
                let fileURL = asset.fileURL!
                
                do {
                    let tcxZipData = try Data(contentsOf: fileURL)
                    self.logger.log("Got tcx data of size \(tcxZipData.count)")
                    
                    do {
                        let tcxData: Data = try tcxZipData.gunzipped()
                        self.logger.log("Unzipped data to size \(tcxData.count)")
                        
                        let parser = XMLParser(data: tcxData)

                        parser.delegate = self
                        parser.parse()
                    } catch {
                        self.logger.error("Unzip failed")
                    }
                    
                } catch {
                    self.logger.error("Can't get data at url:\(fileURL)")
                }
            }
        }

        
    }

    
}

