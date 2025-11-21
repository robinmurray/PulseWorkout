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
    ///  See: https://sites.google.com/site/compendiumofphysicalactivities/help/unit-conversions
    func instantaneousVO2(watts: Double?, weight: Double) -> Double? {
        
        guard let wattsVal = watts else {return nil}
        if weight == 0 {
            return nil
        }
        
        return ((1.8 * 6 * wattsVal) / weight) + 7
        
    }
    
    func proportionHRMax(currentHR: Double?, HRMax: Double?) -> Double? {

        guard let HRMaxVal = HRMax else {return nil}
        guard let currentHRVal = currentHR else {return nil}
        if HRMaxVal == 0 {return nil}
        
        return min(currentHRVal / HRMaxVal, 1)
        
    }
    
    /// Calculate proportion of VO2Max from proportion of HR Max
    func proportionVO2Max(proportionHRMax: Double?) -> Double? {
        guard let proportionHRMaxVal = proportionHRMax else {return nil}
        
        return max((1.408 * proportionHRMaxVal) - 0.451, 0)
        
    }
    
    
    /// Calculate estimated VO2Max from proprtion VO2Max
    func estimatedVO2Max(VO2: Double?, proportionVO2Max: Double?) -> Double? {
        guard let proportionVO2MaxVal = proportionVO2Max else {return nil}
        guard let VO2Val = VO2 else {return nil}
        if proportionVO2MaxVal == 0 {return nil}
        
        return VO2Val / proportionVO2MaxVal
        
        
    }
    
    /// return true / false depending on whether passes validation tests
    func validVO2Estimate(ave60Watts: Double?, ave10Watts: Double?, heartRate: Double?) -> Bool {
        guard let ave60WattsVal = ave60Watts,
              let ave10WattsVal = ave10Watts,
              let heartRateVal = heartRate else {return false}
        
        let HRZone3 = Double(130)
        let HRTHRESHOLD = Double(154)
        let MAX_10_60_GAP_Proportion = 0.1      // only allow 10% difference between 60-sec rolling average and 10-sec average
        
        if heartRateVal < HRZone3 {return false}
        if heartRateVal > HRTHRESHOLD {return false}
        if abs(ave60WattsVal - ave10WattsVal) > (ave60WattsVal * MAX_10_60_GAP_Proportion) {return false}
        
        return true
        
    }
    
    /// Calculate esimated VO2Max from activity
    func calculateVO2Max() -> Double? {
        
        struct CalcVO2Max {
            var ave60Watts: Double?         // 60 second rolling average of power
            var ave10Watts: Double?         // 10 second rolling average of power
            var heartRate: Double?          // Heart rate
            var VO2: Double?                // Instantaneous VO2 ml/kg/min
            var proportionHRMax: Double?    // Proportion of HR Max: 0 - 1
            var proportionVO2Max: Double?   // Proportion of VO2 Max: 0 - 1
            var estimatedVO2Max: Double?    // calculated estimate of VO2 max
            var validEstimate: Bool?        // Whether this reading passes all validation tests
            var validSequenceLength: Int?   // How may items have been consecutively valid
        }
        
        var calcArray: [CalcVO2Max] = []
        
        var VO2Max: Double?

        // get number of points in 60 seconds
        let rolling60Count = Int(60 / trackPointGap)
        let rolling10Count = Int(10 / trackPointGap)

        let rolling60AverageWatts = rollingAverage(inputArray: trackPoints.map( {Double($0.watts ?? 0)} ), rollCount: rolling60Count)
        let rolling10AverageWatts = rollingAverage(inputArray: trackPoints.map( {Double($0.watts ?? 0)} ), rollCount: rolling10Count)

        if rolling60AverageWatts.count == 0 {
            return nil
        }

        let offsetTrackPoints = Array(trackPoints.suffix(rolling60AverageWatts.count))
        let offsetRolling10AverageWatts = Array(rolling10AverageWatts.suffix(rolling60AverageWatts.count))

        
        // array of tuples ( rolling 60 average watts, heart Rate )
        let zip1 = Array(zip(rolling60AverageWatts, offsetTrackPoints.map( {$0.heartRate })))
        // move to array of partial CalcVO2Max
        let tempCalcArray: [CalcVO2Max] = zip1.map( { CalcVO2Max(ave60Watts: $0.0, heartRate: $0.1)})
        
        // array of tuples ( CalcVO2Max(aveWatts: watts, heartRate: heart rate), 10-sec rolling average of watts
        let zip2 = Array(zip(tempCalcArray, offsetRolling10AverageWatts))
        
        calcArray = zip2.map( { CalcVO2Max(ave60Watts: $0.0.ave60Watts, ave10Watts: $0.1, heartRate: $0.0.heartRate) } )
        
        let weight = getWeight(at: Date.now)
        let HRMax = Double(164)
        let HRRest = Double(52)
        
        // calculate estimated VO2 and proportion HR Max at each time point
        calcArray = calcArray.map( {CalcVO2Max(ave60Watts: $0.ave60Watts,
                                               ave10Watts: $0.ave10Watts,
                                               heartRate: $0.heartRate,
                                               VO2: instantaneousVO2(watts: $0.ave60Watts ?? 0,
                                                                     weight: weight),
                                               proportionHRMax: proportionHRMax(currentHR: $0.heartRate, HRMax: HRMax) ) } )
            
        // Calculate VO2 MAx percent at each point
        calcArray = calcArray.map( {CalcVO2Max(ave60Watts: $0.ave60Watts,
                                               ave10Watts: $0.ave10Watts,
                                               heartRate: $0.heartRate,
                                               VO2: $0.VO2,
                                               proportionHRMax: $0.proportionHRMax,
                                               proportionVO2Max: proportionVO2Max(proportionHRMax: $0.proportionHRMax)) } )
        
        // Calculate estaimated VO2Max for each time point as ((1/VO2ReservePercent) * VO2) + VO2Rest
        calcArray = calcArray.map( {CalcVO2Max(ave60Watts: $0.ave60Watts,
                                               ave10Watts: $0.ave10Watts,
                                               heartRate: $0.heartRate,
                                               VO2: $0.VO2,
                                               proportionHRMax: $0.proportionHRMax,
                                               proportionVO2Max: $0.proportionVO2Max,
                                               estimatedVO2Max: estimatedVO2Max(VO2: $0.VO2, proportionVO2Max: $0.proportionVO2Max))} )
        
        // Now test which readings pass validation
        calcArray = calcArray.map( {CalcVO2Max(ave60Watts: $0.ave60Watts,
                                               ave10Watts: $0.ave10Watts,
                                               heartRate: $0.heartRate,
                                               VO2: $0.VO2,
                                               proportionHRMax: $0.proportionHRMax,
                                               proportionVO2Max: $0.proportionVO2Max,
                                               estimatedVO2Max: $0.estimatedVO2Max,
                                               validEstimate: validVO2Estimate(ave60Watts: $0.ave60Watts,
                                                                               ave10Watts: $0.ave10Watts,
                                                                               heartRate: $0.heartRate))} )
        
        
        
        var seqLength: Int = 0
        for i in 0..<calcArray.count {
            if calcArray[i].validEstimate ?? false {
                seqLength += 1
            } else {
                seqLength = 0
            }
            calcArray[i].validSequenceLength = seqLength

        }
        
        let MIN_SEQ_LENGTH = Int(60 / trackPointGap)
        calcArray = calcArray.filter( { ($0.validSequenceLength ?? 0) >= MIN_SEQ_LENGTH })
        
        
        if calcArray.count == 0 {return nil}
        
        
        VO2Max = median( calcArray.map( { $0.estimatedVO2Max } ))
        
        return round(VO2Max! * 10) / 10
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
