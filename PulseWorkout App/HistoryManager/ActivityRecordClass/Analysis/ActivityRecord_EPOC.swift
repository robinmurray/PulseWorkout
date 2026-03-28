//
//  ActivityRecord_EPOC.swift
//  PulseWorkout
//
//  Created by Robin Murray on 08/03/2026.
//

import Foundation



extension ActivityRecord {
    

    func getEPOC() -> Double? {
        
        if !hasHRData || !hasPowerData {
            logger.info("Cannot calculate EPOC for record: \(name)")
            return nil
        }
        
        logger.info("Calculating EPOC for record: \(name)")

        var vo2_aer: Double = 3.5
        var epoc: Double = 0
        let mass = UserProfile.shared.weightKG() ?? 70
        let ftp = UserProfile.shared.FTP(at: self.startDate) ?? 250
        let hr_rest: Double = Double(UserProfile.shared.restHR(at: self.startDate) ?? 50)
        let hr_lt: Double = Double(UserProfile.shared.thresholdHR(at: self.startDate) ?? 154)
        let vo2max: Double = 60
        var epoc_rate: Double
        
        for trackPoint in self.trackPoints {

            let power: Double = Double(trackPoint.watts ?? 0)
//            let vo2_power = power / (4.8 * mass)
            let vo2_power = 60 * power / (4.8 * mass)

            // Note in VO2Max calc we smooth the power...
//            let vo2_power = instantaneousVO2(watts: power, weight: mass)!
            
            let r = power / Double(ftp)
            let hr_expected = hr_rest + (hr_lt - hr_rest) * r
            let hr_factor = min(max((Double(trackPoint.heartRate ?? 0) / hr_expected), 0.9), 1.2)     // clamp(hr / hr_expected, 0.9, 1.2)

            let vo2_true = vo2_power * hr_factor

            vo2_aer += (Double(trackPointGap)/40) * (vo2_true - vo2_aer)

            let delta = max(0, vo2_true - vo2_aer)

            epoc_rate = 0.25 * pow((delta / vo2max), 2) * vo2max

            if power > Double(ftp) {
                epoc_rate = epoc_rate * (1 + (2 * ((power / Double(ftp)) - 1)))
            }
            
            epoc = epoc + (epoc_rate * Double(trackPointGap) / 60)
        }

        return epoc

    }

    
}


