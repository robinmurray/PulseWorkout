//
//  GeneralUtilities.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 09/08/2024.
//

import Foundation
import Accelerate


/// Return next number greater than input number that is 1, 2 or 5 * 10^n
func next125(input: Double) -> Int {
    var output: Double = 1
    
    while output < input {
        if output * 2 >= input {
            return Int(output * 2)
        }
        if output * 5 >= input {
            return Int(output * 5)
        }
        output = output * 10
    }
    
    return Int(output)
}

func getAxisMarksForStepMultiple(max: Double, stepMultiple: Int, intervals: Int) -> [Int] {

    let axisStep = Int(((max / Double(intervals)) / Double(stepMultiple)).rounded(.awayFromZero)) * stepMultiple
    
    let axisMarks: [Int]  = (0...intervals).map({ $0 * axisStep })

    return axisMarks    
}

func getAxisMarksFor125(max: Double, intervals: Int) -> [Int] {

    let minStep = max / Double(intervals)
    
    let axisStep: Int = next125(input: minStep)
    
    let axisMarks: [Int]  = (0...intervals).map({ $0 * axisStep })

    return axisMarks
}

func getScaleFactor(axisMarks1: [Int], axisMarks2: [Int]) -> Double {
    
    return Double(axisMarks1.max()!) / Double(axisMarks2.max()!)
    
}

/// Returns array of cumulative ascent from given array of altitudes
func getAscentFromAltitude(altitudeArray: [Double?]) -> [Double] {

    if altitudeArray.count == 0 {
        return []
    }
    
    var lastValue: Double? = altitudeArray[0]
    var totalAscent: Double = 0
    
    let ascentSequence = altitudeArray.publisher.scan( 0, { runningTotal, newValue in
        if newValue != nil {
            if lastValue != nil {
                if newValue! > lastValue! {
                    totalAscent = runningTotal + (newValue! - lastValue!)
                }
            }
            lastValue = newValue
        }

        return totalAscent})

    return ascentSequence.sequence
    
}

/// Returns array of cumulative descent from given array of altitudes
func getDescentFromAltitude(altitudeArray: [Double]) -> [Double] {

    if altitudeArray.count == 0 {
        return []
    }
    
    var lastValue: Double = altitudeArray[0]
    var totalDescent: Double = 0
    
    let descentSequence = altitudeArray.publisher.scan( 0, { runningTotal, newValue in
        if newValue < lastValue {
            totalDescent = runningTotal + (lastValue - newValue)
            lastValue = newValue
        }
        lastValue = newValue
        return totalDescent})

    return descentSequence.sequence
    
}

func rollingAverage(inputArray: [Double], rollCount: Int) -> [Double] {
    
    if inputArray.count == 0 {
        return []
    }
    
    var rollingAverageBuffer: [Double] = []
    
    let rollingAverageSequence = inputArray.publisher.scan( 0, { _, newValue in
        
        if rollingAverageBuffer.count == rollCount {
            rollingAverageBuffer.removeFirst()
        }
        rollingAverageBuffer.append(newValue)
        
        return rollingAverageBuffer.reduce(0, +) / Double(rollingAverageBuffer.count)
        
    })
    
    return rollingAverageSequence.sequence
}

func segmentAverageSeries( segmentSize: Int, xAxisSeries: [Double], inputSeries: [Double?], includeZeros: Bool, getMidpoints: Bool = false) -> [Double] {

    var outSequence: [Double] = []
    var aveVal: Double = 0
    var aveSeq: [Double] = []
    
    if xAxisSeries.count != inputSeries.count {
//        logger.error("input data series different size to time series")
        return []
    }

    if xAxisSeries.count == 0 {
//        logger.info("No data present for chart trace")
        return []
    }

    let segmentCount = Int((Double(xAxisSeries.max() ?? 1) / Double(segmentSize)).rounded(.up))
    
    var firstIndex = 0
    for segmentStart in stride(from: 0, to: segmentCount * segmentSize, by: segmentSize) {
//        let firstIndex: Int = xAxisSeries.firstIndex(where: { $0 <= Double(segmentStart) })!
        let lastIndex: Int = xAxisSeries.lastIndex(where: { $0 < Double(segmentStart + segmentSize)}) ?? (xAxisSeries.count - 1)
        let subSeq: [Double?] = Array(inputSeries[firstIndex...lastIndex])
        firstIndex = lastIndex + 1

        if !includeZeros {
            aveVal = vDSP.mean(subSeq.filter( { ($0 ?? 0) != 0 } ) as! [Double])
        } else {
            aveVal = vDSP.mean(subSeq.compactMap( { $0 }))
        }
        
        if getMidpoints {
            aveSeq = Array(repeating: 0, count: subSeq.count)
            if subSeq.count != 0 {
                aveSeq[(subSeq.count - 1)/2] = 1
            }
        } else {
            aveSeq = Array(repeating: aveVal, count: subSeq.count)
        }

        outSequence += aveSeq
    }
    
    return outSequence
}



class TimeAverageBuilder {
    
    var seconds: Double
    struct TimeAverageEntry {
        var valDate: Date
        var val:Double
    }
    var rollingBuffer: [TimeAverageEntry] = []
    
    init(seconds: Double) {
        self.seconds = seconds
    }
    
    func addValue(newValue: Double) -> Double {
        let now = NSDate()
        
        rollingBuffer = rollingBuffer.filter({ now.timeIntervalSince($0.valDate) < seconds })

        rollingBuffer.append(TimeAverageEntry(valDate: now as Date, val: newValue))
                
        return rollingBuffer.map({$0.val}).reduce(0, +) / Double(rollingBuffer.count)
        
    }
}


func getAxisTimeGap( elapsedTimeSeries: [Int] ) -> Int {
    
    guard let maxElapsedSeconds = elapsedTimeSeries.last else {
        return 60
    }
    
    let axisGapSeconds = [10, 15, 30, 60, 120, 300, 600, 900, 1800]
    let MAX_AXIS_GAPS = 8
    
    for gap in axisGapSeconds {
        if (gap * MAX_AXIS_GAPS) >= maxElapsedSeconds {
            return gap
        }
            
    }

    return axisGapSeconds.last!

}

func getAxisTimeMarks(elapsedTimeSeries: [Int] ) -> [Int] {

    guard let maxElapsedSeconds = elapsedTimeSeries.last else {
        return [0, 60]
    }
    
    let axisGap = getAxisTimeGap(elapsedTimeSeries: elapsedTimeSeries)
    let maxMark: Int = Int(((Double(maxElapsedSeconds) / Double(axisGap)).rounded(.up))) * axisGap
    
    return stride(from: 0, through: maxMark, by: axisGap).map( { $0 } )
}


func getAxisMetersGap( distanceMetersSeries: [Int] ) -> Int {
    
    guard let maxDistanceMeters = distanceMetersSeries.max() else {
        return 10000
    }
    
    let axisGapMeters: [Int] = [10, 100, 1000, 2000, 5000, 10000]
    let MAX_AXIS_GAPS: Int = 8
    
    for gap in axisGapMeters {
        if (gap * MAX_AXIS_GAPS) >= maxDistanceMeters {
            return gap
        }
            
    }

    return axisGapMeters.last!

}


func getAxisMetersMarks(distanceMetersSeries: [Int] ) -> [Int] {

    guard let maxDistanceMeters = distanceMetersSeries.max() else {
        return [0, 10000]
    }
    
    let axisGap: Int = getAxisMetersGap(distanceMetersSeries: distanceMetersSeries)
    let maxMark: Int = Int(((Double(maxDistanceMeters) / Double(axisGap)).rounded(.up))) * axisGap
    
    return stride(from: 0, through: maxMark, by: axisGap).map( { $0 } )
}


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
