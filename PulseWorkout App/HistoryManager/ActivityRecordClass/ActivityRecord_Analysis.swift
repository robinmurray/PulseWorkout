//
//  ActivityRecord_Analysis.swift
//  PulseWorkout
//
//  Created by Robin Murray on 07/11/2025.
//

import Foundation
import MapKit

extension ActivityRecord {
    
    /// Return incremental Summable TSS score for a wattage - taking into account FTP and trackPointGap
    func incrementalTSSSummable(watts: Int?, seconds: Int) -> Double {

        guard let currentFTP = FTP else {return 0}

        return (100 * pow(((Double(watts ?? 0)) / Double(currentFTP)), 2) * (Double(seconds) / (60 * 60) ))

    }


    /// Return total Summable TSS for the entire activity
    func getTotalTSSSummable() -> Double? {

        let TSSSeries = trackPoints.map({ incrementalTSSSummable(watts: $0.watts, seconds: trackPointGap) })

        let thisTSS = TSSSeries.reduce(0, +)

        let roundedTSS = round(thisTSS * 10) / 10

        return roundedTSS

    }

    
    /// Return total  TSS for the entire activity
    func getTotalTSS() -> Double? {

        guard let nonZeroFTP = FTP else { return 0 }
        
        // First remove trackpoints that are stationary
        let movingTrackPoints = trackPoints.filter( {$0.speed ?? 0 > 0} )
        if movingTrackPoints.count == 0 {
            return 0
        }
        
        // calculate total moving time as number of points while moving * gap
        let totalMovingSeconds = movingTrackPoints.count * trackPointGap
        
        // get number of points in 30 seconds
        let rollingCount = Int(30 / trackPointGap)
        
        let rollingAverageWatts = rollingAverage(inputArray: movingTrackPoints.map( {Double($0.watts ?? 0)} ), rollCount: rollingCount)

        if rollingAverageWatts.count == 0 {
            return 0
        }
        
        // raise to the 4th power
        let rollingAverageWatts_4 = rollingAverageWatts.map( {pow($0 , 4)})
        
        // take average of 4th powers
        let aveWatts_4 = rollingAverageWatts_4.reduce(0, +) / Double(rollingAverageWatts_4.count)
        
        normalisedPower = round(sqrt(sqrt(aveWatts_4)))
        intensityFactor = round(1000 * (normalisedPower! / Double(nonZeroFTP))) / 1000
        TSS = intensityFactor! * normalisedPower! * 100 * Double(totalMovingSeconds) / (3600 * Double(nonZeroFTP))
        
        TSS = round(TSS! * 10) / 10

        return TSS
    }

    func getTSSByPowerZone() -> [Double] {
     
        if (TSSSummableByPowerZone.count > 0)
            && ((TSSSummable ?? 0) > 0)
            && ((TSS ?? 0) > 0) {
            
            return TSSSummableByPowerZone.map( { round((TSS! * $0 / TSSSummable! ) * 10) / 10 } )
        }
        else {
            return []
        }
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
                x.map({ _ in incrementalTSSSummable(watts: power, seconds: trackPointGap) })

            } else {
                TSSSeries = trackPoints.filter({(($0.heartRate ?? 0) >= Double(lowerLimit)) && (($0.heartRate ?? 0) < Double(HRZoneLimits[index+1]))})
                    .map({ _ in incrementalTSSSummable(watts: power, seconds: trackPointGap) })
            }

            let thisTSS = TSSSeries.reduce(0, +)
            let roundedTSS = round(thisTSS * 10) / 10
            calcTSSbyHRZone.append(roundedTSS)
        }

        return calcTSSbyHRZone

    }


    func getTSSSummableByPowerZone() -> [Double] {

        guard let currentFTP = FTP else {return []}

        var calcTSSbyPowerZone: [Double] = []
        var TSSSeries: [Double]

        for (index, lowerLimit) in powerZoneLimits.enumerated() {

            if index > powerZoneLimits.count - 2 {
                TSSSeries = trackPoints.filter({($0.watts ?? 0) >= lowerLimit})
                    .map({ incrementalTSSSummable(watts: $0.watts, seconds: trackPointGap) })

            } else {
                TSSSeries = trackPoints.filter({(($0.watts ?? 0) >= lowerLimit) && (($0.watts ?? 0) < powerZoneLimits[index+1])})
                    .map({ incrementalTSSSummable(watts: $0.watts, seconds: trackPointGap) })
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
            calcMovingTimebyPowerZone[index] = round( max((round(movingTime * 10 ) / 10) - calcMovingTimebyPowerZone.reduce(0, +) + value, 0) * 10 ) / 10
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
            calcMovingTimebyHRZone[index] = round(max((round(movingTime * 10 ) / 10) - calcMovingTimebyHRZone.reduce(0, +) + value, 0) * 10) / 10
        }
//        calcMovingTimebyHRZone[0] = max((round(movingTime * 10 ) / 10) - calcMovingTimebyHRZone.suffix(from: 1).reduce(0, +), 0)

        return calcMovingTimebyHRZone
    }

    func getWeight(at: Date) -> Double {
        return 69
    }
    
    
    /// Calculate instantaneous VO2 usage
    func instantaneousVO2(watts: Double, weight: Double) -> Double {
        
        if weight == 0 {
            return 0
        }
        
        return ((12.35 * watts) + 300) / weight
        
    }
    
    func HRReservePercent(currentHR: Double?, HRRest: Double, HRMax: Double) -> Double {

        let HRReserve = HRMax - HRRest
        let workingHR: Double = max(currentHR ?? HRRest, HRRest)
        
        return (workingHR - HRRest) / HRReserve
        
    }
    
    
    /// Calculate esimated VO2Max from activity
    func calculateVO2Max() -> Double {
        
        struct CalcVO2Max {
            var aveWatts: Double?
            var SDWatts: Double?
            var heartRate: Double?
            var VO2: Double?
            var HRReservePercent: Double?
            var VO2ReservePercent: Double?
            var estimatedVO2Max: Double?
        }
        
        var calcArray: [CalcVO2Max] = []
        
        var VO2Max: Double = 0

        // get number of points in 30 seconds
        let rollingCount = Int(30 / trackPointGap)
        
        let rollingAverageWatts = rollingAverage(inputArray: trackPoints.map( {Double($0.watts ?? 0)} ), rollCount: rollingCount)

        if rollingAverageWatts.count == 0 {
            return 0
        }

        let rollingSDWatts = rollingAverageWatts.map( { _ in Double(10) })
                
        let offsetTrackPoints = Array(trackPoints.suffix(rollingAverageWatts.count))
        
        // array of tuples ( rolling average watts, heart Rate )
        let zip1 = Array(zip(rollingAverageWatts, offsetTrackPoints.map( {$0.heartRate })))
        // move to array of partial CalcVO2Max
        let tempCalcArray: [CalcVO2Max] = zip1.map( { CalcVO2Max(aveWatts: $0.0, heartRate: $0.1)})
        
        // array of tuples ( CalcVO2Max(aveWatts: watts, heartRate: heart rate), Standard deviation of watts
        let zip2 = Array(zip(tempCalcArray, rollingSDWatts))
        
        calcArray = zip2.map( { CalcVO2Max(aveWatts: $0.0.aveWatts, SDWatts: $0.1, heartRate: $0.0.heartRate) } )
        
        let weight = getWeight(at: Date.now)
        let HRMax = Double(168)
        let HRRest = Double(52)
        
        // calculate estimated VO2 and HRReservePercent at each time point
        calcArray = calcArray.map( {CalcVO2Max(aveWatts: $0.aveWatts,
                                               SDWatts: $0.SDWatts,
                                               heartRate: $0.heartRate,
                                               VO2: instantaneousVO2(watts: $0.aveWatts ?? 0,
                                                                     weight: weight),
                                               HRReservePercent: HRReservePercent(currentHR: $0.heartRate,
                                                                                  HRRest: HRRest,
                                                                                  HRMax: HRMax) ) } )
            
        // Set VO2 reserve percent to HR reserve percent
        calcArray = calcArray.map( {CalcVO2Max(aveWatts: $0.aveWatts,
                                               SDWatts: $0.SDWatts,
                                               heartRate: $0.heartRate,
                                               VO2: $0.VO2,
                                               HRReservePercent: $0.HRReservePercent,
                                               VO2ReservePercent: $0.HRReservePercent) } )
            

        // VO2 Rest estimated by formaul for VO2 from power, when power is zero!
        let VO2Rest = instantaneousVO2(watts: 0, weight: weight)
        
        // Calculate estaimated VO2Max for each time point as ((1/VO2ReservePercent) * VO2) + VO2Rest
        calcArray = calcArray.map( {CalcVO2Max(aveWatts: $0.aveWatts,
                                               SDWatts: $0.SDWatts,
                                               heartRate: $0.heartRate,
                                               VO2: $0.VO2,
                                               HRReservePercent: $0.HRReservePercent,
                                               VO2ReservePercent: $0.VO2ReservePercent,
                                               estimatedVO2Max: (((1/($0.VO2ReservePercent ?? 1)) * (($0.VO2 ?? VO2Rest) - VO2Rest))) + VO2Rest  )} )
        
        let HRZone3 = Double(130)
        let MAX_SD_Watts = Double(20)
        
        calcArray = calcArray.filter( { (($0.heartRate ?? 0) > HRZone3) &&
                                        (($0.SDWatts ?? 0) < MAX_SD_Watts)})
        
        VO2Max = median( calcArray.map( { $0.estimatedVO2Max } ))
        
        return round(VO2Max * 10) / 10
    }
    
    
    func addActivityAnalysis() {

        FTP = settingsManager.userPowerMetrics.currentFTP
        powerZoneLimits = settingsManager.userPowerMetrics.powerZoneLimits
        
        thesholdHR = 154
        
//        let HRZoneRatios = [0, 0.68, 0.83, 0.94, 1.05]
        let HRZoneRatios = [0, 0.68, 0.83, 0.93, 1.00]

        if let currentThesholdHR = thesholdHR {
            HRZoneLimits = HRZoneRatios.map({ Int(round($0 * Double(currentThesholdHR))) })
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
