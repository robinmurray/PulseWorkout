//
//  ActivityRecord_Analysis.swift
//  PulseWorkout
//
//  Created by Robin Murray on 07/11/2025.
//

import Foundation
import MapKit

extension ActivityRecord {

    func getWeight(at: Date) -> Double {
        return 69
    }
   
    
    func getMovingTimeByPowerZone() -> [Double] {

        guard let currentFTP = profileFTP else {return []}

        var calcMovingTimebyPowerZone: [Double] = []
        var thisTime: Double

        for (index, lowerLimit) in profilePowerZoneLimits.enumerated() {

            if hasPowerData {
                if index > profilePowerZoneLimits.count - 2 {
                    thisTime = Double(trackPoints.filter({($0.watts ?? 0) >= lowerLimit}).count * trackPointGap)

                } else {
                    thisTime = Double(trackPoints.filter({(($0.watts ?? 0) >= lowerLimit) && (($0.watts ?? 0) < profilePowerZoneLimits[index+1])}).count * trackPointGap)

                }
            }
            else {
                thisTime = 0
            }

            calcMovingTimebyPowerZone.append(thisTime)
        }

        // Make sure all elements add up to movingTime!
        for (index, value) in calcMovingTimebyPowerZone.enumerated() {
            calcMovingTimebyPowerZone[index] = round( max((round(movingTime * 10 ) / 10) - calcMovingTimebyPowerZone.reduce(0, +) + value, 0) * 10 ) / 10
        }

        return calcMovingTimebyPowerZone
    }


    func getMovingTimeByHRZone() -> [Double] {

        var calcMovingTimebyHRZone: [Double] = []
        var thisTime: Double

        guard let currentThesholdHR = profileThresholdHR else {return []}

        let movingPoints = trackPoints.filter({($0.speed ?? 0) > 0 })

        for (index, lowerLimit) in profileHRZoneLimits.enumerated() {

            if index > profileHRZoneLimits.count - 2 {

                thisTime = Double(movingPoints.filter({($0.heartRate ?? 0) >= Double(lowerLimit)}).count * trackPointGap)

            } else {
                thisTime = Double(movingPoints.filter({(($0.heartRate ?? 0) >= Double(lowerLimit)) && (($0.heartRate ?? 0) < Double(profileHRZoneLimits[index+1]))})
                    .count * trackPointGap)
            }

            calcMovingTimebyHRZone.append(thisTime)
        }

        // Make sure all elements add up to movingTime!
        for (index, value) in calcMovingTimebyHRZone.enumerated() {
            calcMovingTimebyHRZone[index] = round(max((round(movingTime * 10 ) / 10) - calcMovingTimebyHRZone.reduce(0, +) + value, 0) * 10) / 10
        }
//        calcMovingTimebyHRZone[0] = max((round(movingTime * 10 ) / 10) - calcMovingTimebyHRZone.suffix(from: 1).reduce(0, +), 0)

        return calcMovingTimebyHRZone
    }

    
    func addActivityAnalysis() {

        profileFTP = settingsManager.userPowerMetrics.currentFTP
        profilePowerZoneLimits = settingsManager.userPowerMetrics.powerZoneLimits
        profileThresholdHR = 154
        profileMaxHR = 164
        profileRestHR = 52
        profileWeightKG = 69
        
//        let HRZoneRatios = [0, 0.68, 0.83, 0.94, 1.05]
        let HRZoneRatios = [0, 0.68, 0.83, 0.93, 1.00]

        if let currentThesholdHR = profileThresholdHR {
            profileHRZoneLimits = HRZoneRatios.map({ Int(round($0 * Double(currentThesholdHR))) })
        }

        TSSSummable = getTotalTSSSummable()
        TSS = getTotalTSS()
        TSSEstimatebyHRZone = getTSSEstimateByHRZone()
        estimatedTSSbyHR = round(TSSEstimatebyHRZone.reduce(0, +) * 10) / 10
        TSSSummableByPowerZone = getTSSSummableByPowerZone()
        TSSbyPowerZone = getTSSByPowerZone()
        movingTimebyPowerZone = getMovingTimeByPowerZone()
        movingTimebyHRZone = getMovingTimeByHRZone()
        
        estimatedVO2Max = calculateVO2Max()
        TRIMP = getTRIMP()
        TRIMPByHRZone = getTRIMPByHRZone()
        estimatedEPOC = getEPOC()

        loAltitudeMeters = trackPoints.filter({ $0.altitudeMeters != nil }).map({ $0.altitudeMeters! }).min()
        hiAltitudeMeters = trackPoints.filter({ $0.altitudeMeters != nil }).map({ $0.altitudeMeters! }).max()
        maxCadence = trackPoints.filter({ $0.cadence != nil }).map({ $0.cadence! }).max() ?? 0
        totalDescent = getTotalDescent()

        // Calculate average power
        var powerSeries = trackPoints.filter( { $0.watts != nil } ).map( { $0.watts! } )
        if !(settingsManager.avePowerZeros) {
            powerSeries = powerSeries.filter( { $0 != 0 } )
        }

        let powerSeriesLen = powerSeries.count
        if powerSeriesLen > 0 {
            averagePower = powerSeries.reduce(0, +) / powerSeriesLen
        } else {
            averagePower = 0
        }

        if trackPoints.count > 0 {
            let startTime = trackPoints[0].time
            averageSegmentSize = getAxisTimeGap(elapsedTimeSeries: trackPoints.map( { Int($0.time.timeIntervalSince(startTime)) }))
            HRSegmentAverages = segmentAverageSeries(
                segmentSize: averageSegmentSize!,
                xAxisSeries: trackPoints.map( { Double($0.time.timeIntervalSince(startTime)) }),
                inputSeries: trackPoints.map( { $0.heartRate }),
                includeZeros: true,
                returnFullSeries: false).map( { Int($0) })

            powerSegmentAverages = segmentAverageSeries(
                segmentSize: averageSegmentSize!,
                xAxisSeries: trackPoints.map( { Double($0.time.timeIntervalSince(startTime)) }),
                inputSeries: trackPoints.map( { Double($0.watts ?? 0) }),
                includeZeros: settingsManager.avePowerZeros,
                returnFullSeries: false).map( { Int($0) })

            cadenceSegmentAverages = segmentAverageSeries(
                segmentSize: averageSegmentSize!,
                xAxisSeries: trackPoints.map( { Double($0.time.timeIntervalSince(startTime)) }),
                inputSeries: trackPoints.map( { Double($0.cadence ?? 0) }),
                includeZeros: settingsManager.aveCadenceZeros,
                returnFullSeries: false).map( { Int($0) })

            self.logger.info("averageSegmentSize : \(self.averageSegmentSize ?? 0)")
            self.logger.info("HRSegmentAverages : \(self.HRSegmentAverages)")
            self.logger.info("powerSegmentAverages : \(self.powerSegmentAverages)")
            self.logger.info("cadenceSegmentAverages : \(self.cadenceSegmentAverages)")
        }

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



    func getRouteCoordinates() -> [CLLocationCoordinate2D] {

        // Create list of non-null locations
        return self.trackPoints.filter(
            {$0.latitude != nil && $0.longitude != nil}).map(
                {CLLocationCoordinate2D(latitude: $0.latitude!, longitude: $0.longitude!)})

    }
}
