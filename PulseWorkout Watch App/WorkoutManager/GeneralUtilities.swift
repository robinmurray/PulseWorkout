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
