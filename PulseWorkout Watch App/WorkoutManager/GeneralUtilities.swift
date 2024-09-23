//
//  GeneralUtilities.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 09/08/2024.
//

import Foundation


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
func getAscentFromAltitude(altitudeArray: [Double]) -> [Double] {

    if altitudeArray.count == 0 {
        return []
    }
    
    var lastValue: Double = altitudeArray[0]
    var totalAscent: Double = 0
    
    let ascentSequence = altitudeArray.publisher.scan( 0, { runningTotal, newValue in
        if newValue > lastValue {
            totalAscent = runningTotal + (newValue - lastValue)
            lastValue = newValue
        }
        lastValue = newValue
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
