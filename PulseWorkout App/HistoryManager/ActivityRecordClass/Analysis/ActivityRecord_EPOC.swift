//
//  ActivityRecord_EPOC.swift
//  PulseWorkout
//
//  Created by Robin Murray on 08/03/2026.
//

import Foundation



extension ActivityRecord {
    

    func getEPOCForTrackPoints(tpSeries: [TrackPoint]) -> Double? {
        
        if !hasHRData && !hasPowerData {
            logger.info("Cannot calculate EPOC for record: \(name)")
            return nil
        }
        
        let EPOCSeries = tpSeries.map({ incrementalEPOC(watts: $0.watts, HR: $0.heartRate, seconds: trackPointGap) })
        
        let EPOC = EPOCSeries.reduce(0, +)
        
        let roundedEPOC = round(EPOC * 10) / 10
        
        return roundedEPOC
        
    }
        
    /// Calculate EPOC in ml / Kg
    /// Use model
    /// EPOC Rate  = 0.02*EXP(5*(HRr + Power Intensity)/2)   ml/Kg/ min
    /// HRr = relative heart rate (proportioon between HRrest and HRmax
    /// Power Intensity = Power / FTP
    func getEPOC() -> Double? {
        
        // Must have at least one of HR or Power data - ideally both
        if !hasHRData && !hasPowerData {
            logger.info("Cannot calculate EPOC for record: \(name)")
            return nil
        }
        
        logger.info("Calculating EPOC for record: \(name)")

        // Pass all trackpoints to the calculation
        return getEPOCForTrackPoints(tpSeries: trackPoints)
        
    }

    
    /// Return incremental EPOC  - taking into account FTP and trackPointGap
    /// EPOC Rate  = 0.02*EXP(5*(HRr + Power Intensity)/2)   ml/Kg/ min
    /// HRr = relative heart rate (proportioon between HRrest and HRmax
    /// Power Intensity = Power / FTP
    func incrementalEPOC(watts: Int?, HR: Double?, seconds: Int) -> Double {

        guard let FTP = profileFTP,
              let restHR = profileRestHR,
              let maxHR = profileMaxHR else {return 0}
        
        let MAX_POWER_INTENSITY: Double = 4             // Assume any power reading over 4* FTP is bogus
        let power: Double = Double(watts ?? 0)
        let powerIntensity: Double = min(power/Double(FTP), MAX_POWER_INTENSITY)

        let restHRD = Double(restHR)
        let maxHRD = Double(maxHR)
        let HR = min(HR ?? 0, 1.1 * maxHRD)               // Don't allow HR more than 10% over max HR

        let HRrel = min(max(HR - restHRD, 0), (maxHRD - restHRD))/(maxHRD - restHRD)
        
        let intensity = (hasHRData && hasPowerData) ? (powerIntensity + HRrel) / 2 : (hasHRData ? HRrel : powerIntensity)
        
        let epoc_rate = 0.02 * exp(5 * intensity)
        
        return epoc_rate * Double(seconds) / 60

    }

    
    /// Calculate EPOC by HR Zone
    func getEPOCByHRZone() -> [Double] {
        
        logger.info("Calculating EPOC by HR zone for record: \(name)")
            
        return getStressByHRZone(stressFunction: getEPOCForTrackPoints)

    }

    
    /// Calculate EPOC by Power Zone
    func getEPOCByPowerZone() -> [Double] {
        
        logger.info("Calculating EPOC by Power zone for record: \(name)")
            
        return getStressByPowerZone(stressFunction: getEPOCForTrackPoints)

    }
    
}


