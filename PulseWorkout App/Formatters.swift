//
//  File.swift
//  PulseWorkout
//
//  Created by Robin Murray on 06/12/2024.
//

import Foundation


func durationFormatter( seconds: Int ) -> String {
    var durationText: String = ""
    let duration = Duration.seconds(seconds)
    
    if (seconds % 60) != 0 {
        if seconds > 3600 {
            durationText = duration.formatted(
                .time(pattern: .hourMinuteSecond(padHourToLength: 1)))
        }
        else {
            durationText = duration.formatted(
                .time(pattern: .minuteSecond(padMinuteToLength: 1)))
        }
    }
    else {
        durationText = duration.formatted(
            .time(pattern: .hourMinute(padHourToLength: 1)))
    }
    
    return durationText
}



func distanceFormatter (distance: Double, forceMeters: Bool = false) -> String {
    var unit = UnitLength.meters
    var displayDistance: Double = distance.rounded()
    if (distance > 1000) && (!forceMeters) {
        unit = UnitLength.kilometers
        displayDistance = distance / 1000
        if displayDistance > 100 {
            displayDistance = (displayDistance * 10).rounded() / 10
        } else if displayDistance > 10 {
            displayDistance = (displayDistance * 100).rounded() / 100
        } else {
            displayDistance = (displayDistance * 10).rounded() / 10
        }

    }
    
    return  Measurement(value: displayDistance,
                       unit: unit)
    .formatted(.measurement(width: .abbreviated,
                            usage: .asProvided
                           )
    )

}

func speedFormatter( speed: Double ) -> String {
    // var unit = UnitSpeed.kilometersPerHour
    var speedKPH = speed * 3.6
    
    speedKPH = max(speedKPH, 0)
    
    return String(format: "%.1f", speedKPH) + " k/h"
    
}

func durationFormatter( elapsedSeconds: Double, minimizeLength: Bool = false ) -> String {
    
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.zeroFormattingBehavior = .pad
    if minimizeLength {

        if elapsedSeconds < 3600 {
            formatter.allowedUnits = [.minute, .second]
        }
        if (Int(elapsedSeconds) % 60) == 0 {
            formatter.allowedUnits = [.hour, .minute]
        }
    }
    
    
    return formatter.string(from: elapsedSeconds) ?? ""
}

func elapsedTimeFormatter( elapsedSeconds: Double, minimizeLength: Bool = false ) -> String {
    return durationFormatter( elapsedSeconds: elapsedSeconds, minimizeLength: minimizeLength )
}


func powerFormatter( watts: Double ) -> String {
    
    return Measurement(value: watts,
                       unit: UnitPower.watts)
            .formatted(.measurement(width: .abbreviated,
                                    usage: .asProvided))
}

func heartRateFormatter( heartRate: Double ) -> String {
    

    return heartRate.formatted(.number.precision(.fractionLength(0)))
    
}

func cadenceFormatter( cadence: Double ) -> String {
    
    return cadence.formatted(.number.precision(.fractionLength(0)))
    
}

func energyFormatter( energy: Double ) -> String {
    
    return Measurement(value: energy,
                       unit: UnitEnergy.kilocalories).formatted(.measurement(
                        width: .abbreviated,
                        usage: .workout))
}

func TSSFormatter(TSS: Double) -> String {
    return String(format: "%.1f", TSS)
}

