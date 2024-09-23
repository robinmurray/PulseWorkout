//
//  GeneralUtilitiesTest.swift
//  PulseWorkout Watch AppTests
//
//  Created by Robin Murray on 09/08/2024.
//

import Foundation
import XCTest

@testable import PulseWorkout_Watch_App

final class GeneralUtilitiesTest: XCTestCase {
    
    func testnext125() throws {
        
        XCTAssert(next125(input: 1) == 1)
        XCTAssert(next125(input: 2) == 2)
        XCTAssert(next125(input: 3) == 5)
        XCTAssert(next125(input: 4) == 5)
        XCTAssert(next125(input: 5) == 5)
        XCTAssert(next125(input: 6) == 10)
        XCTAssert(next125(input: 7) == 10)
        XCTAssert(next125(input: 9) == 10)
        XCTAssert(next125(input: 10) == 10)
        XCTAssert(next125(input: 11) == 20)
        XCTAssert(next125(input: 15) == 20)
        XCTAssert(next125(input: 20) == 20)
        XCTAssert(next125(input: 21) == 50)
        XCTAssert(next125(input: 49) == 50)
        XCTAssert(next125(input: 51) == 100)
        XCTAssert(next125(input: 101) == 200)
        
    }
    
    func testgetAxisMarksForStepMultiple() throws {
        
        XCTAssert(getAxisMarksForStepMultiple(max: 160, stepMultiple: 10, intervals: 4) == [0, 40, 80, 120, 160])
        XCTAssert(getAxisMarksForStepMultiple(max: 160, stepMultiple: 10, intervals: 5) == [0, 40, 80, 120, 160, 200])
        XCTAssert(getAxisMarksForStepMultiple(max: 160, stepMultiple: 10, intervals: 6) == [0, 30, 60, 90, 120, 150, 180])
        
        XCTAssert(getAxisMarksForStepMultiple(max: 160, stepMultiple: 5, intervals: 4) == [0, 40, 80, 120, 160])
        XCTAssert(getAxisMarksForStepMultiple(max: 160, stepMultiple: 5, intervals: 5) == [0, 35, 70, 105, 140, 175])
        XCTAssert(getAxisMarksForStepMultiple(max: 160, stepMultiple: 5, intervals: 6) == [0, 30, 60, 90, 120, 150, 180])
        
        XCTAssert(getAxisMarksForStepMultiple(max: 180, stepMultiple: 10, intervals: 4) == [0, 50, 100, 150, 200])
        
        XCTAssert(getAxisMarksForStepMultiple(max: 210, stepMultiple: 10, intervals: 4) == [0, 60, 120, 180, 240])
        
        
    }
    
    func testgetAxisMarksFor125() throws {
        
        XCTAssert(getAxisMarksFor125(max: 160, intervals: 4) == [0, 50, 100, 150, 200])
        XCTAssert(getAxisMarksFor125(max: 160, intervals: 5) == [0, 50, 100, 150, 200, 250])
        XCTAssert(getAxisMarksFor125(max: 160, intervals: 8) == [0, 20, 40, 60, 80, 100, 120, 140, 160])
        XCTAssert(getAxisMarksFor125(max: 160, intervals: 9) == [0, 20, 40, 60, 80, 100, 120, 140, 160, 180])
        
        XCTAssert(getAxisMarksFor125(max: 40, intervals: 4) == [0, 10, 20, 30, 40])
        
        XCTAssert(getAxisMarksFor125(max: 1800, intervals: 4) == [0, 500, 1000, 1500, 2000])
        
    }
    
    func testgetScaleFactor() throws {
        XCTAssert(getScaleFactor(axisMarks1: [0, 1, 2, 3, 4], axisMarks2: [0, 1, 2, 3, 4]) == 1)
        XCTAssert(getScaleFactor(axisMarks1: [0, 2, 3, 6, 8], axisMarks2: [0, 1, 2, 3, 4]) == 2)
        XCTAssert(getScaleFactor(axisMarks1: [0, 2, 3, 6, 8], axisMarks2: [0, 10, 20, 30, 40]) == 0.2)
        
    }
    
    
    func testgetAscentFromAltitude() throws {
        XCTAssert(getAscentFromAltitude(altitudeArray: []) == [])
        XCTAssert(getAscentFromAltitude(altitudeArray: [10, 11, 12]) == [0, 1, 2])
        XCTAssert(getAscentFromAltitude(altitudeArray: [10, 11, 12, 10, 15, 20]) == [0, 1, 2, 2, 7, 12])
        
    }
    
    func testgetDescentFromAltitude() throws {
        XCTAssert(getDescentFromAltitude(altitudeArray: []) == [])
        XCTAssert(getDescentFromAltitude(altitudeArray: [10, 11, 12]) == [0, 0, 0])
        XCTAssert(getDescentFromAltitude(altitudeArray: [10, 11, 12, 10, 15, 20, 15, 10, 15]) == [0, 0, 0, 2, 2, 2, 7, 12, 12])

    }

}


