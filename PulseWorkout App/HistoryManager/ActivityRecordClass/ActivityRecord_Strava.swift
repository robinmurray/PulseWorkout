//
//  ActivityRecord_Strava.swift
//  PulseWorkout
//
//  Created by Robin Murray on 26/02/2025.
//

import Foundation
import CloudKit

#if os(iOS)
import StravaSwift
#endif
import Accelerate

extension ActivityRecord {

    #if os(iOS)
    
    func saveToStrava() {
        
        stravaSaveStatus = StravaSaveStatus.saving.rawValue
        StravaUploadActivity(activityRecord: self,
                             completionHandler: saveStravaId,
                             failureCompletionHandler: { self.stravaSaveStatus = StravaSaveStatus.notSaved.rawValue }).execute()
        
    }
    
    
    /// On completion of save to Strava, update the cloudkit record
    func saveStravaId(newStravaId: Int) {
        self.logger.info("Record saved to Strava with Id \(newStravaId)")
        // Set strava status and strava Id
        
        self.stravaId = newStravaId
        self.stravaSaveStatus = StravaSaveStatus.saved.rawValue
   
        let activityCKRecord = CKRecord(recordType: recordType,
                                        recordID: recordID)
        activityCKRecord["stravaSaveStatus"] = stravaSaveStatus
        activityCKRecord["stravaId"] = stravaId

        // Only update if already saved! - should get picked up by record save
        // if not then will update saved record on next display...
        if !toSave {
            self.logger.info("Updating activity record :: \(self.name) :: saved to Strava with Id \(newStravaId)")
            
            CKForceUpdateOperation(ckRecord: activityCKRecord, completionFunction: { _ in }).execute()

        }
        
    }
    
    func fromStravaActivity(_ stravaActivity: StravaActivity) {

        /*

         "distance" : 24931.4,
         "moving_time" : 4500,
         "elapsed_time" : 4500,
         "total_elevation_gain" : 0,
         "type" : "Ride",
         "sport_type" : "MountainBikeRide",
         "workout_type" : null,
         "id" : 154504250376823,
         "external_id" : "garmin_push_12345678987654321",
         "upload_id" : 987654321234567891234,
         "start_date" : "2018-05-02T12:15:09Z",
         "start_date_local" : "2018-05-02T05:15:09Z",
         "timezone" : "(GMT-08:00) America/Los_Angeles",
         "utc_offset" : -25200,
         "start_latlng" : null,
         "end_latlng" : null,
         "location_city" : null,
         "location_state" : null,
         "location_country" : "United States",
         "achievement_count" : 0,
         "kudos_count" : 3,
         "comment_count" : 1,
         "athlete_count" : 1,
         "photo_count" : 0,
         "map" : {
           "id" : "a12345678987654321",
           "summary_polyline" : null,
           "resource_state" : 2
         },
         "trainer" : true,
         "commute" : false,
         "manual" : false,
         "private" : false,
         "flagged" : false,
         "gear_id" : "b12345678987654321",
         "from_accepted_tag" : false,
         "average_speed" : 5.54,
         "max_speed" : 11,
         "average_cadence" : 67.1,
         "average_watts" : 175.3,
         "weighted_average_watts" : 210,
         "kilojoules" : 788.7,
         "device_watts" : true,
         "has_heartrate" : true,
         "average_heartrate" : 140.3,
         "max_heartrate" : 178,
         "max_watts" : 406,
         "pr_count" : 0,
         "total_photo_count" : 1,
         "has_kudoed" : false,
         "suffer_score" : 82

         public let id: Int?  // * Need to store StravaId - DONE - note nil/0
         public let resourceState: ResourceState?
         public let externalId: String?
         public let uploadId: Int?


         public let startDate: Date?

         public let map: Map?
         public let trainer: Bool?

         public let workoutType: WorkoutType?


         */

        self.recordID = CloudKitOperation().getCKRecordID()  // *
        self.recordName = self.recordID.recordName      // *

        stravaId = stravaActivity.id
        name = stravaActivity.name ?? ""
        stravaType = stravaActivity.type?.rawValue ?? "Ride"
        workoutTypeId = getHKWorkoutActivityType(stravaType).rawValue
        workoutLocationId = getHKWorkoutSessionLocationType(stravaType).rawValue

//        sportType = "Ride" // *
        /* Possible Strava Values
        "AlpineSki", "BackcountrySki", "Badminton", "Canoeing", "Crossfit", "EBikeRide", "Elliptical", "EMountainBikeRide", "Golf", "GravelRide", "Handcycle", "HighIntensityIntervalTraining", "Hike", "IceSkate", "InlineSkate", "Kayaking", "Kitesurf", "MountainBikeRide", "NordicSki", "Pickleball", "Pilates", "Racquetball", "Ride", "RockClimbing", "RollerSki", "Rowing", "Run", "Sail", "Skateboard", "Snowboard", "Snowshoe", "Soccer", "Squash", "StairStepper", "StandUpPaddling", "Surfing", "Swim", "TableTennis", "Tennis", "TrailRun", "Velomobile", "VirtualRide", "VirtualRow", "VirtualRun", "Walk", "WeightTraining", "Wheelchair", "Windsurf", "Workout", "Yoga"

         Foot Sports

         Run
         Trail Run
         Walk
         Hike
         Virtual Run

         Cycle Sports

         Ride
         Mountain Bike Ride
         Gravel Ride
         E-Bike Ride
         E-Mountain Bike Ride
         Velomobile
         Virtual Ride


         Water Sports

         Canoe
         Kayak
         Kitesurf
         Rowing
         Stand Up Paddling
         Surf
         Swim
         Windsurf


         Winter Sports

         Ice Skate
         Alpine Ski
         Backcountry Ski
         Nordic Ski
         Snowboard
         Snowshoe


         Other Sports:

         Handcycle
         Inline Skate
         Rock Climb
         Roller Ski
         Golf
         Skateboard
         Football (Soccer)
         Wheelchair
         Badminton
         Tennis
         Pickleball
         Crossfit
         Elliptical
         Stair Stepper
         Weight Training
         Yoga
         Workout
         HIIT
         Pilates
         Table Tennis
         Squash
         Racquetball
         */

        startDateLocal = stravaActivity.startDateLocal ?? Date()
        startDate = stravaActivity.startDate ?? Date()
        timeZone = TimeZone(identifier: stravaActivity.timeZone ?? "GMT") ?? TimeZone(identifier: "GMT")!
        GMTOffset = timeZone.secondsFromGMT()

        elapsedTime = stravaActivity.elapsedTime ?? 0
        pausedTime = (stravaActivity.elapsedTime ?? 0) - (stravaActivity.movingTime ?? 0)
        movingTime = stravaActivity.movingTime ?? 0
        activityDescription = stravaActivity.activityDescription ?? ""
        distanceMeters = stravaActivity.distance ?? 0
        totalAscent = stravaActivity.totalElevationGain
        loAltitudeMeters = stravaActivity.lowElevation
        hiAltitudeMeters = stravaActivity.highElevation
        totalDescent = 0        // *

        averageHeartRate = stravaActivity.averageHeartRate ?? 0
        averageCadence = Int(stravaActivity.averageCadence ?? 0)
        averagePower = Int(stravaActivity.averagePower ?? 0)
        averageSpeed = stravaActivity.averageSpeed ?? 0
        maxPower = Int(stravaActivity.maxPower ?? 0)
        maxSpeed = stravaActivity.maxSpeed ?? 0
        maxHeartRate = stravaActivity.maxHeartRate ?? 0

        activeEnergy = stravaActivity.kiloJoules ?? 0 // * UNITS!
        timeOverHiAlarm = 0
        timeUnderLoAlarm = 0
        hiHRLimit = nil
        loHRLimit = nil
        stravaSaveStatus = StravaSaveStatus.saved.rawValue
        stravaType = stravaActivity.sportType ?? "Ride"

        setToSave(false)

        toDelete = false

        tcxFileName = baseFileName + ".gz"
        JSONFileName = baseFileName + ".json"
        autoPause = true // *

        mapSnapshotURL = nil // *
        mapSnapshotImage = nil // *
        mapSnapshotAsset = nil // *

        trackPoints = [] // *
    }

    
    /// Fetch the strava record for this activityRecord and update any fields
    func fetchUpdateFromStrava(dataCache: DataCache) {
        
        self.dataCache = dataCache
        
        if let id = stravaId {
            StravaFetchActivity(stravaActivityId: id,
                                completionHandler: updateFromStravaActivity).execute()
        }
        
    }
    
    
    /// Update fields from strava record as completion to fetch
    func updateFromStravaActivity(stravaActivity: StravaActivity) {
        logger.info("Updating record after strava fetch")
        

        DispatchQueue.main.async {
            self.name = stravaActivity.name ?? ""
            self.stravaType = stravaActivity.type?.rawValue ?? "Ride"
            self.workoutTypeId = getHKWorkoutActivityType(self.stravaType).rawValue
            self.workoutLocationId = getHKWorkoutSessionLocationType(self.stravaType).rawValue
            self.activityDescription = stravaActivity.activityDescription ?? ""
            self.totalAscent = stravaActivity.totalElevationGain
        }


        let activityCKRecord = CKRecord(recordType: recordType,
                                        recordID: recordID)
        activityCKRecord["name"] = (stravaActivity.name ?? "") as CKRecordValue
        activityCKRecord["stravaType"] = (stravaActivity.type?.rawValue ?? "Ride") as CKRecordValue
        activityCKRecord["workoutTypeId"] = getHKWorkoutActivityType(self.stravaType).rawValue as CKRecordValue
        activityCKRecord["workoutLocationId"] = getHKWorkoutSessionLocationType(self.stravaType).rawValue as CKRecordValue
        activityCKRecord["activityDescription"] = (stravaActivity.activityDescription ?? "") as CKRecordValue
        activityCKRecord["totalAscent"] = stravaActivity.totalElevationGain as CKRecordValue?

        // Only update if already saved! - should get picked up by record save
        // if not then will update saved record on next display...
        if !toSave {
            CKForceUpdateOperation(ckRecord: activityCKRecord,
                                   completionFunction: { _ in }).execute()
        }

    }

    
    
    /// Add trackpoints to activity record derived from strava streams
    func addStreams(_ streams: [StravaSwift.Stream]) {
        var desiredStreamLength: Int?
        var timeStreamPresent = false
        var timeSeries: [Date] = []
        var heartRateSeries: [Double?] = []
        var distanceMetersSeries: [Double?] = []
        var altitudeMetersSeries: [Double?] = []
        var cadenceSeries: [Int?] = []
        var wattsSeries: [Int?] = []
        var speedSeries: [Double?] = []
        var latitudeSeries: [Double?] = []
        var longitudeSeries: [Double?] = []

        for stream in streams {

            logger.info("Adding stream: \(stream.type?.rawValue ?? "nil")")
            if let streamLength = desiredStreamLength {
                if stream.data?.count != streamLength {
                    logger.error("Streams of different length!")
                    return
                }
            }
            else {
                desiredStreamLength = stream.data?.count
            }


            switch stream.type?.rawValue ?? "unknown" {
            case "time":
                timeStreamPresent = true
                let timeStream = stream.data!.map({ $0 as? Double ?? 0 })
                timeSeries = timeStream.map({ startDate.addingTimeInterval( $0 ) })
                let timeGaps = zip(timeStream, timeStream.dropFirst()).map({ Int($1 - $0) })
                logger.info("Time gaps - minimum : \(timeGaps.min() ?? 0) :: maximum \(timeGaps.max() ?? 0)")

                let medianTimeGap = (timeGaps.count == 0) ? 1 : timeGaps.sorted(by: <)[timeGaps.count / 2]

                // Set trackpoint gap to time difference between items in series (ignoring pauses!)
                trackPointGap = Int(medianTimeGap)
                logger.info("trackPointGap : \(self.trackPointGap)")
                break

            case "distance":
                distanceMetersSeries = stream.data!.map({ $0 as? Double? ?? nil })
                break

            case "latlng":
                latitudeSeries = stream.data!.map({ ($0 as? [Double?] ?? [nil, nil])[0] })
                longitudeSeries = stream.data!.map({ ($0 as? [Double?] ?? [nil, nil])[1] })
                hasLocationData = true
                break

            case "heartrate":
                heartRateSeries = stream.data!.map({ $0 as? Double? ?? nil })
                hasHRData = true
                break

            case "altitude":
                altitudeMetersSeries = stream.data!.map({ $0 as? Double? ?? nil })
                break

            case "cadence":
                cadenceSeries = stream.data!.map({ $0 as? Int? ?? nil })
                break

            case "watts":
                wattsSeries = stream.data!.map({ $0 as? Int? ?? nil })
                hasPowerData = true
                break

            case "velocity_smooth":
                speedSeries = stream.data!.map({ $0 as? Double? ?? nil })
                break

            default:
                logger.info("Unknown stream type \(stream.seriesType ?? "nil")")
            }
        }



        if !timeStreamPresent {
            logger.error("No time stream!")
            return
        }

        for (index, timepoint) in timeSeries.enumerated() {

            trackPoints.append(TrackPoint(time: timepoint,
                                          heartRate: heartRateSeries.count == desiredStreamLength ? heartRateSeries[index] : nil,
                                          latitude: latitudeSeries.count == desiredStreamLength ? latitudeSeries[index] : nil,
                                          longitude: longitudeSeries.count == desiredStreamLength ? longitudeSeries[index] : nil,
                                          altitudeMeters: altitudeMetersSeries.count == desiredStreamLength ? altitudeMetersSeries[index] : nil,
                                          distanceMeters: distanceMetersSeries.count == desiredStreamLength ? distanceMetersSeries[index] : nil,
                                          cadence: cadenceSeries.count == desiredStreamLength ? cadenceSeries[index] : nil,
                                          speed: speedSeries.count == desiredStreamLength ? speedSeries[index] : nil,
                                          watts: wattsSeries.count == desiredStreamLength ? wattsSeries[index] : nil
                                         )
                                )
        }
        addActivityAnalysis()

    }
    #endif


}
