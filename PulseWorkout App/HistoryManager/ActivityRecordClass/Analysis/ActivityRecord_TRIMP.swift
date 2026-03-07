//
//  ActivityRecord_TRIMP.swift
//  PulseWorkout
//
//  Created by Robin Murray on 06/03/2026.
//

import Foundation
import HealthKit

private let TRIMP_A_CONSTANT: [HKBiologicalSex: Double] = [HKBiologicalSex.male: 0.64,
                                                           HKBiologicalSex.female: 0.86]
private let TRIMP_B_CONSTANT: [HKBiologicalSex: Double] = [HKBiologicalSex.male: 1.92,
                                                           HKBiologicalSex.female: 1.67]

extension ActivityRecord {
    
    func fetchBiologicalSex() -> HKBiologicalSex {
        
        let healthStore = HKHealthStore()
        
        do {
            let sex = try healthStore.biologicalSex().biologicalSex
            switch sex {
            case .female:
                logger.log("Biological sex: female")
            case .male:
                logger.log("Biological sex: male")
            case .other:
                logger.log("Biological sex: other")
            case .notSet:
                logger.log("Biological sex: not set")
            @unknown default:
                logger.log("Biological sex: unknown default")
            }
            return sex
        } catch {
            logger.error("Failed to fetch biological sex: \(error.localizedDescription)")
            return .notSet
        }
    }

    func incrementalTRIMP(A: Double, B: Double, currentHR: Double?, HRRest: Int?, HRMax: Int?, seconds: Int) -> Double {
        
        guard let HR = currentHR,
              let HRR = HRRest,
              let HRM = HRMax
        else {return 0}
        
        let HRRel = max(HR - Double(HRR), 0) / Double(max(HRM - HRR, 1))
        
        return A * HRRel * exp(B * HRRel) * (Double(seconds) / 60)
        
    }
    
    /// Calculate Training Impulse - TRIMP for a given series of trackpoints
    /// See https://www.firstbeat.com/en/blog/what-is-trimp/
    func getTRIMPForTrackPoints(tpSeries: [TrackPoint]) -> Double? {
        
        if !hasHRData {return nil}
        
        let A = TRIMP_A_CONSTANT[fetchBiologicalSex()] ?? TRIMP_A_CONSTANT[HKBiologicalSex.male]!
        let B = TRIMP_B_CONSTANT[fetchBiologicalSex()] ?? TRIMP_B_CONSTANT[HKBiologicalSex.male]!

        
        let TRIMPSeries = tpSeries.map({ incrementalTRIMP(A: A,
                                                          B: B,
                                                          currentHR: $0.heartRate,
                                                          HRRest: profileRestHR,
                                                          HRMax: profileMaxHR,
                                                          seconds: trackPointGap) })

        let thisTRIMP = TRIMPSeries.reduce(0, +)

        let roundedTRIMP = round(thisTRIMP * 10) / 10

        return roundedTRIMP
        
    }
    
    /// Calculate Training Impulse - TRIMP
    /// See https://www.firstbeat.com/en/blog/what-is-trimp/
    func getTRIMP() -> Double? {
        
        logger.info("Calculating TRIMP for record: \(name)")
        return getTRIMPForTrackPoints(tpSeries: trackPoints)

    }
    
    
    /// Calculate Training Impulse - TRIMP by HR Zone
    func getTRIMPByHRZone() -> [Double] {

        var calcTRIMPbyHRZone: [Double] = []
        var trackPointsInZone: [TrackPoint]

        logger.info("Calculating TRIMP by zone for record: \(name)")
        if !hasHRData {return []}
        
        for (index, lowerLimit) in profileHRZoneLimits.enumerated() {

            if index > profileHRZoneLimits.count - 2 {

                trackPointsInZone = trackPoints.filter({($0.heartRate ?? 0) >= Double(lowerLimit)})


            } else {
                trackPointsInZone = trackPoints.filter({(($0.heartRate ?? 0) >= Double(lowerLimit)) && (($0.heartRate ?? 0) < Double(profileHRZoneLimits[index+1]))})

            }

            calcTRIMPbyHRZone.append(getTRIMPForTrackPoints(tpSeries: trackPointsInZone) ?? 0)
        }

        return calcTRIMPbyHRZone

    }
    
}
