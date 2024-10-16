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

    func testRollingAverage() throws {
        XCTAssert(rollingAverage(inputArray: [], rollCount: 10) == [])
        XCTAssert(rollingAverage(inputArray: [1, 2, 3], rollCount: 10) == [1, 1.5, 2])
        XCTAssert(rollingAverage(inputArray: [1, 2, 3, 4, 5, 6, 2, 8, 4, 10], rollCount: 5) == [1, 1.5, 2, 2.5, 3, 4, 4, 5, 5, 6])


    }


    func testTimeAverageBuilder() throws {
        
        let TAB = TimeAverageBuilder(seconds: 3)
        XCTAssert(TAB.addValue(newValue: 2) == 2)
        XCTAssert(TAB.addValue(newValue: 4) == 3)
        XCTAssert(TAB.addValue(newValue: 6) == 4)
        XCTAssert(TAB.addValue(newValue: 8) == 5)
        sleep(2)
        
        XCTAssert(TAB.addValue(newValue: 10) == 6)
        XCTAssert(TAB.addValue(newValue: 12) == 7)

        sleep(2)
        // Initial set should be kicked out now...
        XCTAssert(TAB.addValue(newValue: 8) == 10)
        XCTAssert(TAB.addValue(newValue: 14) == 11)

        sleep(2)
        // second set should be kicked out now...
        XCTAssert(TAB.addValue(newValue: 2) == 8)
        XCTAssert(TAB.addValue(newValue: 4) == 7)

        
    }

    func testGetAxisTimeGap() throws {

        XCTAssert(getAxisTimeGap(elapsedTimeSeries: []) == 60)
        XCTAssert(getAxisTimeGap(elapsedTimeSeries: [0, 5]) == 10)
        XCTAssert(getAxisTimeGap(elapsedTimeSeries: [0, 10]) == 10)
        XCTAssert(getAxisTimeGap(elapsedTimeSeries: [0, 60]) == 10)
        XCTAssert(getAxisTimeGap(elapsedTimeSeries: [0, 120]) == 15)

        XCTAssert(getAxisTimeGap(elapsedTimeSeries: [0, 240]) == 30)
        XCTAssert(getAxisTimeGap(elapsedTimeSeries: [0, 420]) == 60)
        XCTAssert(getAxisTimeGap(elapsedTimeSeries: [0, 800]) == 120)
        XCTAssert(getAxisTimeGap(elapsedTimeSeries: [0, 1600]) == 300)
        XCTAssert(getAxisTimeGap(elapsedTimeSeries: [0, 3000]) == 600)
        XCTAssert(getAxisTimeGap(elapsedTimeSeries: [0, 6000]) == 900)
        XCTAssert(getAxisTimeGap(elapsedTimeSeries: [0, 12000]) == 1800)
        XCTAssert(getAxisTimeGap(elapsedTimeSeries: [0, 24000]) == 1800)

        XCTAssert(getAxisTimeGap(elapsedTimeSeries: [0, 240000]) == 1800)


    }

    func testGetAxisTimeMarks() throws {

        XCTAssert(getAxisTimeMarks(elapsedTimeSeries: []) == [0, 60])
        XCTAssert(getAxisTimeMarks(elapsedTimeSeries: [0, 5]) == [0, 10])
        XCTAssert(getAxisTimeMarks(elapsedTimeSeries: [0, 10]) == [0, 10])
        XCTAssert(getAxisTimeMarks(elapsedTimeSeries: [0, 60]) == [0, 10, 20, 30, 40, 50, 60])
        XCTAssert(getAxisTimeMarks(elapsedTimeSeries: [0, 120]) == [0, 15, 30, 45, 60, 75, 90, 105, 120])

        XCTAssert(getAxisTimeMarks(elapsedTimeSeries: [0, 240]) == [0, 30, 60, 90, 120, 150, 180, 210, 240])
        XCTAssert(getAxisTimeMarks(elapsedTimeSeries: [0, 420]) == [0, 60, 120, 180, 240, 300, 360, 420])
        XCTAssert(getAxisTimeMarks(elapsedTimeSeries: [0, 800]) == [0, 120, 240, 360, 480, 600, 720, 840])
        XCTAssert(getAxisTimeMarks(elapsedTimeSeries: [0, 1600]) == [0, 300, 600, 900, 1200, 1500, 1800])
        XCTAssert(getAxisTimeMarks(elapsedTimeSeries: [0, 3000]) == [0, 600, 1200, 1800, 2400, 3000])
        XCTAssert(getAxisTimeMarks(elapsedTimeSeries: [0, 6000]) == [0, 900, 1800, 2700, 3600, 4500, 5400, 6300])
        XCTAssert(getAxisTimeMarks(elapsedTimeSeries: [0, 12000]) == [0, 1800, 3600, 5400, 7200, 9000, 10800, 12600])
        XCTAssert(getAxisTimeMarks(elapsedTimeSeries: [0, 24000]) == [0, 1800, 3600, 5400, 7200, 9000, 10800, 12600,
                                                                      14400, 16200, 18000, 19800, 21600, 23400, 25200])



    }
    
    func testGetAxisMetersGap() throws {

        XCTAssert(getAxisMetersGap(distanceMetersSeries: []) == 10000)
        XCTAssert(getAxisMetersGap(distanceMetersSeries: [0, 5]) == 10)
        XCTAssert(getAxisMetersGap(distanceMetersSeries: [0, 10]) == 10)
        XCTAssert(getAxisMetersGap(distanceMetersSeries: [0, 60]) == 10)
        XCTAssert(getAxisMetersGap(distanceMetersSeries: [0, 120]) == 100)

        XCTAssert(getAxisMetersGap(distanceMetersSeries: [0, 240]) == 100)
        XCTAssert(getAxisMetersGap(distanceMetersSeries: [0, 420]) == 100)
        XCTAssert(getAxisMetersGap(distanceMetersSeries: [0, 800]) == 100)
        XCTAssert(getAxisMetersGap(distanceMetersSeries: [0, 1600]) == 1000)
        XCTAssert(getAxisMetersGap(distanceMetersSeries: [0, 3000]) == 1000)
        XCTAssert(getAxisMetersGap(distanceMetersSeries: [0, 6000]) == 1000)
        XCTAssert(getAxisMetersGap(distanceMetersSeries: [0, 12000]) == 2000)
        XCTAssert(getAxisMetersGap(distanceMetersSeries: [0, 24000]) == 5000)

        XCTAssert(getAxisMetersGap(distanceMetersSeries: [0, 240000]) == 10000)


    }

    func testGetAxisMetersMarks() throws {

        XCTAssert(getAxisMetersMarks(distanceMetersSeries: []) == [0, 10000])
        XCTAssert(getAxisMetersMarks(distanceMetersSeries: [0, 5]) == [0, 10])
        XCTAssert(getAxisMetersMarks(distanceMetersSeries: [0, 10]) == [0, 10])
        XCTAssert(getAxisMetersMarks(distanceMetersSeries: [0, 60]) == [0, 10, 20, 30, 40, 50, 60])
        XCTAssert(getAxisMetersMarks(distanceMetersSeries: [0, 120]) == [0, 100, 200])

        XCTAssert(getAxisMetersMarks(distanceMetersSeries: [0, 240]) == [0, 100, 200, 300])
        XCTAssert(getAxisMetersMarks(distanceMetersSeries: [0, 420]) == [0, 100, 200, 300, 400, 500])
        XCTAssert(getAxisMetersMarks(distanceMetersSeries: [0, 800]) == [0, 100, 200, 300, 400, 500, 600, 700, 800])
        XCTAssert(getAxisMetersMarks(distanceMetersSeries: [0, 1600]) == [0, 1000, 2000])
        XCTAssert(getAxisMetersMarks(distanceMetersSeries: [0, 3000]) == [0, 1000, 2000, 3000])
        XCTAssert(getAxisMetersMarks(distanceMetersSeries: [0, 6000]) == [0, 1000, 2000, 3000, 4000, 5000, 6000])
        XCTAssert(getAxisMetersMarks(distanceMetersSeries: [0, 12000]) == [0, 2000, 4000, 6000, 8000, 10000, 12000])
        XCTAssert(getAxisMetersMarks(distanceMetersSeries: [0, 24000]) == [0, 5000, 10000, 15000, 20000, 25000])
        XCTAssert(getAxisMetersMarks(distanceMetersSeries: [0, 40001]) == [0, 10000, 20000, 30000, 40000, 50000])

    }
    
    func testDurationFormatter() throws {

        XCTAssert(durationFormatter(seconds: 10) == "0:10")
        XCTAssert(durationFormatter(seconds: 100) == "1:40")

        XCTAssert(durationFormatter(seconds: 3610) == "1:00:10")

        XCTAssert(durationFormatter(seconds: 60) == "0:01")
        XCTAssert(durationFormatter(seconds: 600) == "0:10")

        XCTAssert(durationFormatter(seconds: 3600) == "1:00")
        XCTAssert(durationFormatter(seconds: 3660) == "1:01")

    }
}




