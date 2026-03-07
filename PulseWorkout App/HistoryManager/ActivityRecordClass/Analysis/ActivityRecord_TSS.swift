//
//  ActivityRecord_TSS.swift
//  PulseWorkout
//
//  Created by Robin Murray on 06/03/2026.
//

import Foundation


extension ActivityRecord {
   
    /// Return incremental Summable TSS score for a wattage - taking into account FTP and trackPointGap
    func incrementalTSSSummable(watts: Int?, seconds: Int) -> Double {

        guard let currentFTP = profileFTP else {return 0}

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

        guard let nonZeroFTP = profileFTP else { return 0 }
        
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

        guard let currentThesholdHR = profileThresholdHR,
              let currentFTP = profileFTP else {return []}

        for (index, lowerLimit) in profileHRZoneLimits.enumerated() {
            let power = profilePowerZoneLimits[index+1]
            if index > profileHRZoneLimits.count - 2 {

                let x = trackPoints.filter({($0.heartRate ?? 0) >= Double(lowerLimit)})
                TSSSeries =
                x.map({ _ in incrementalTSSSummable(watts: power, seconds: trackPointGap) })

            } else {
                TSSSeries = trackPoints.filter({(($0.heartRate ?? 0) >= Double(lowerLimit)) && (($0.heartRate ?? 0) < Double(profileHRZoneLimits[index+1]))})
                    .map({ _ in incrementalTSSSummable(watts: power, seconds: trackPointGap) })
            }

            let thisTSS = TSSSeries.reduce(0, +)
            let roundedTSS = round(thisTSS * 10) / 10
            calcTSSbyHRZone.append(roundedTSS)
        }

        return calcTSSbyHRZone

    }


    func getTSSSummableByPowerZone() -> [Double] {

        guard let currentFTP = profileFTP else {return []}

        var calcTSSbyPowerZone: [Double] = []
        var TSSSeries: [Double]

        for (index, lowerLimit) in profilePowerZoneLimits.enumerated() {

            if index > profilePowerZoneLimits.count - 2 {
                TSSSeries = trackPoints.filter({($0.watts ?? 0) >= lowerLimit})
                    .map({ incrementalTSSSummable(watts: $0.watts, seconds: trackPointGap) })

            } else {
                TSSSeries = trackPoints.filter({(($0.watts ?? 0) >= lowerLimit) && (($0.watts ?? 0) < profilePowerZoneLimits[index+1])})
                    .map({ incrementalTSSSummable(watts: $0.watts, seconds: trackPointGap) })
            }
            let thisTSS = TSSSeries.reduce(0, +)
            let roundedTSS = round(thisTSS * 10) / 10
            calcTSSbyPowerZone.append(roundedTSS)
        }

        return calcTSSbyPowerZone
    }


}
