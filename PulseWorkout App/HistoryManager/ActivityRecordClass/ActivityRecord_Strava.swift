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

        self.recordID = CloudKitManager().getCKRecordID()  // *
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
                timeSeries = timeStream.map({ startDateLocal.addingTimeInterval( $0 ) })
                let timeGaps = zip(timeStream, timeStream.dropFirst()).map({ Int($1 - $0) })
                logger.info("Time gaps - minimum : \(timeGaps.min() ?? 0) :: maximum \(timeGaps.max() ?? 0)")

                let medianTimeGap = (timeGaps.count == 0) ? 1 : timeGaps.sorted(by: <)[timeGaps.count / 2]

                // Set trackpoint gap to time difference between items in series (ignoring pauses!)
                trackPointGap = Int(medianTimeGap)

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


    func addActivityAnalysis() {
        FTP = 275
        thesholdHR = 154


        let powerZoneRatios = [0, 0.55, 0.75, 0.9, 1.05, 1.2]
        if let currentFTP = FTP {
            powerZoneLimits = powerZoneRatios.map({ Int(round($0 * Double(currentFTP))) })
        }

        let HRZoneRatios = [0, 0.68, 0.83, 0.94, 1.05]
        if let currentThesholdHR = thesholdHR {
            HRZoneLimits = HRZoneRatios.map({ Int(round($0 * Double(currentThesholdHR))) })
        }

        TSS = getTotalTSS()
        TSSEstimatebyHRZone = getTSSEstimateByHRZone()
        estimatedTSSbyHR = round(TSSEstimatebyHRZone.reduce(0, +) * 10) / 10
        TSSbyPowerZone = getTSSByPowerZone()
        movingTimebyPowerZone = getMovingTimeByPowerZone()
        movingTimebyHRZone = getMovingTimeByHRZone()

        loAltitudeMeters = trackPoints.filter({ $0.altitudeMeters != nil }).map({ $0.altitudeMeters! }).min()
        hiAltitudeMeters = trackPoints.filter({ $0.altitudeMeters != nil }).map({ $0.altitudeMeters! }).max()
        maxCadence = trackPoints.filter({ $0.cadence != nil }).map({ $0.cadence! }).max() ?? 0
        totalDescent = getTotalDescent()

        // Calculate average power
        var powerSeries = trackPoints.filter( { $0.watts != nil } ).map( { $0.watts! } )
        if !(settingsManager?.avePowerZeros ?? false) {
            powerSeries = powerSeries.filter( { $0 != 0 } )
        }

        let powerSeriesLen = powerSeries.count
        if powerSeriesLen > 0 {
            averagePower = powerSeries.reduce(0, +) / powerSeriesLen
        } else {
            averagePower = 0
        }

        averageSegmentSize = getAxisTimeGap(elapsedTimeSeries: trackPoints.map( { Int($0.time.timeIntervalSince(startDateLocal)) }))
        HRSegmentAverages = segmentAverageSeries(
            segmentSize: averageSegmentSize!,
            xAxisSeries: trackPoints.map( { Double($0.time.timeIntervalSince(startDateLocal)) }),
            inputSeries: trackPoints.map( { $0.heartRate }),
            includeZeros: true,
            returnFullSeries: false).map( { Int($0) })

        powerSegmentAverages = segmentAverageSeries(
            segmentSize: averageSegmentSize!,
            xAxisSeries: trackPoints.map( { Double($0.time.timeIntervalSince(startDateLocal)) }),
            inputSeries: trackPoints.map( { Double($0.watts ?? 0) }),
            includeZeros: settingsManager?.avePowerZeros ?? false,
            returnFullSeries: false).map( { Int($0) })

        cadenceSegmentAverages = segmentAverageSeries(
            segmentSize: averageSegmentSize!,
            xAxisSeries: trackPoints.map( { Double($0.time.timeIntervalSince(startDateLocal)) }),
            inputSeries: trackPoints.map( { Double($0.cadence ?? 0) }),
            includeZeros: settingsManager?.aveCadenceZeros ?? false,
            returnFullSeries: false).map( { Int($0) })

        self.logger.info("averageSegmentSize : \(self.averageSegmentSize ?? 0)")
        self.logger.info("HRSegmentAverages : \(self.HRSegmentAverages)")
        self.logger.info("powerSegmentAverages : \(self.powerSegmentAverages)")
        self.logger.info("cadenceSegmentAverages : \(self.cadenceSegmentAverages)")



    }


    func getTotalDescent() -> Double {

        let altitudeData = trackPoints.filter({ $0.altitudeMeters != nil }).map( { $0.altitudeMeters ?? 0})
        if altitudeData.count > 1 {
            // altitudeChanges = array of ascnets & descents - descents are negative
            let altitudeChanges = zip(altitudeData, altitudeData.dropFirst()).map( {$1 - $0} )
            let descents = altitudeChanges.filter({ $0 < 0 }).map({ -1 * $0 })
            return round(descents.reduce(0, +) * 10) / 10
        }
        return 0
    }


    /// Return incremental TSS score for a wattage - taking into account FTP and trackPointGap
    func incrementalTSS(watts: Int?, ftp: Int, seconds: Int) -> Double {

        return (100 * pow(((Double(watts ?? 0)) / Double(ftp)), 2) * (Double(seconds) / (60 * 60) ))

    }


    /// Return total TSS for the entire activity
    func getTotalTSS() -> Double? {

        guard let currentFTP = FTP else {return nil}

        let TSSSeries = trackPoints.map({ incrementalTSS(watts: $0.watts, ftp: currentFTP, seconds: trackPointGap) })

        let thisTSS = TSSSeries.reduce(0, +)

        let roundedTSS = round(thisTSS * 10) / 10

        return roundedTSS

    }


    func getTSSEstimateByHRZone() -> [Double] {

        var calcTSSbyHRZone: [Double] = []
        var TSSSeries: [Double]

        guard let currentThesholdHR = thesholdHR,
              let currentFTP = FTP else {return []}

        for (index, lowerLimit) in HRZoneLimits.enumerated() {
            let power = powerZoneLimits[index+1]
            if index > HRZoneLimits.count - 2 {

                let x = trackPoints.filter({($0.heartRate ?? 0) >= Double(lowerLimit)})
                TSSSeries =
                x.map({ _ in incrementalTSS(watts: power, ftp: currentFTP, seconds: trackPointGap) })

            } else {
                TSSSeries = trackPoints.filter({(($0.heartRate ?? 0) >= Double(lowerLimit)) && (($0.heartRate ?? 0) < Double(HRZoneLimits[index+1]))})
                    .map({ _ in incrementalTSS(watts: power, ftp: currentFTP, seconds: trackPointGap) })
            }

            let thisTSS = TSSSeries.reduce(0, +)
            let roundedTSS = round(thisTSS * 10) / 10
            calcTSSbyHRZone.append(roundedTSS)
        }

        return calcTSSbyHRZone

    }


    func getTSSByPowerZone() -> [Double] {

        guard let currentFTP = FTP else {return []}

        var calcTSSbyPowerZone: [Double] = []
        var TSSSeries: [Double]

        for (index, lowerLimit) in powerZoneLimits.enumerated() {

            if index > powerZoneLimits.count - 2 {
                TSSSeries = trackPoints.filter({($0.watts ?? 0) >= lowerLimit})
                    .map({ incrementalTSS(watts: $0.watts, ftp: currentFTP, seconds: trackPointGap) })

            } else {
                TSSSeries = trackPoints.filter({(($0.watts ?? 0) >= lowerLimit) && (($0.watts ?? 0) < powerZoneLimits[index+1])})
                    .map({ incrementalTSS(watts: $0.watts, ftp: currentFTP, seconds: trackPointGap) })
            }
            let thisTSS = TSSSeries.reduce(0, +)
            let roundedTSS = round(thisTSS * 10) / 10
            calcTSSbyPowerZone.append(roundedTSS)
        }

        return calcTSSbyPowerZone
    }


    func getMovingTimeByPowerZone() -> [Double] {

        guard let currentFTP = FTP else {return []}

        var calcMovingTimebyPowerZone: [Double] = []
        var thisTime: Double

        for (index, lowerLimit) in powerZoneLimits.enumerated() {

            if hasPowerData {
                if index > powerZoneLimits.count - 2 {
                    thisTime = Double(trackPoints.filter({($0.watts ?? 0) >= lowerLimit}).count * trackPointGap)

                } else {
                    thisTime = Double(trackPoints.filter({(($0.watts ?? 0) >= lowerLimit) && (($0.watts ?? 0) < powerZoneLimits[index+1])}).count * trackPointGap)

                }
            }
            else {
                thisTime = 0
            }

            calcMovingTimebyPowerZone.append(thisTime)
        }

        // Make sure all elements add up to movingTime!
        for (index, value) in calcMovingTimebyPowerZone.enumerated() {
            calcMovingTimebyPowerZone[index] = max((round(movingTime * 10 ) / 10) - calcMovingTimebyPowerZone.reduce(0, +) + value, 0)
        }

        return calcMovingTimebyPowerZone
    }


    func getMovingTimeByHRZone() -> [Double] {

        var calcMovingTimebyHRZone: [Double] = []
        var thisTime: Double

        guard let currentThesholdHR = thesholdHR else {return []}

        let movingPoints = trackPoints.filter({($0.speed ?? 0) > 0 })

        for (index, lowerLimit) in HRZoneLimits.enumerated() {

            if index > HRZoneLimits.count - 2 {

                thisTime = Double(movingPoints.filter({($0.heartRate ?? 0) >= Double(lowerLimit)}).count * trackPointGap)

            } else {
                thisTime = Double(movingPoints.filter({(($0.heartRate ?? 0) >= Double(lowerLimit)) && (($0.heartRate ?? 0) < Double(HRZoneLimits[index+1]))})
                    .count * trackPointGap)
            }

            calcMovingTimebyHRZone.append(thisTime)
        }

        // Make sure all elements add up to movingTime!
        for (index, value) in calcMovingTimebyHRZone.enumerated() {
            calcMovingTimebyHRZone[index] = max((round(movingTime * 10 ) / 10) - calcMovingTimebyHRZone.reduce(0, +) + value, 0)
        }
//        calcMovingTimebyHRZone[0] = max((round(movingTime * 10 ) / 10) - calcMovingTimebyHRZone.suffix(from: 1).reduce(0, +), 0)

        return calcMovingTimebyHRZone
    }

    func getRouteCoordinates() -> [CLLocationCoordinate2D] {

        // Create list of non-null locations
        return self.trackPoints.filter(
            {$0.latitude != nil && $0.longitude != nil}).map(
                {CLLocationCoordinate2D(latitude: $0.latitude!, longitude: $0.longitude!)})

    }
}
