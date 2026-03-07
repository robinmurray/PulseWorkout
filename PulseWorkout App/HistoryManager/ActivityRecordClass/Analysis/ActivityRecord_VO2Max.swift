//
//  ActivityRecord_VO2Max.swift
//  PulseWorkout
//
//  Created by Robin Murray on 06/03/2026.
//

import Foundation


extension ActivityRecord {

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
        
        // Must have valid power data and HR data
        if !hasPowerData || !hasHRData {
            return nil
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
 
    
}

