//
//  FormattersTest.swift
//  PulseWorkout Watch AppTests
//
//  Created by Robin Murray on 06/12/2024.
//

import Testing
import XCTest

@testable import PulseWorkout_Watch_App


final class FormattersTest: XCTestCase {
    
    func testDurationFormatter() throws {

        XCTAssert(durationFormatter(seconds: 10) == "0:10")
        XCTAssert(durationFormatter(seconds: 100) == "1:40")

        XCTAssert(durationFormatter(seconds: 3610) == "1:00:10")

        XCTAssert(durationFormatter(seconds: 60) == "0:01")
        XCTAssert(durationFormatter(seconds: 600) == "0:10")

        XCTAssert(durationFormatter(seconds: 3600) == "1:00")
        XCTAssert(durationFormatter(seconds: 3660) == "1:01")

        print(durationFormatter(elapsedSeconds: 10, minimizeLength: true))
        XCTAssert(durationFormatter(elapsedSeconds: 10, minimizeLength: true) == "00:10")
        XCTAssert(durationFormatter(elapsedSeconds: 100, minimizeLength: true) == "01:40")

        XCTAssert(durationFormatter(elapsedSeconds: 3610, minimizeLength: true) == "01:00:10")

        XCTAssert(durationFormatter(elapsedSeconds: 60, minimizeLength: true) == "00:01")
        XCTAssert(durationFormatter(elapsedSeconds: 600, minimizeLength: true) == "00:10")

        XCTAssert(durationFormatter(elapsedSeconds: 3600, minimizeLength: true) == "01:00")
        XCTAssert(durationFormatter(elapsedSeconds: 3660, minimizeLength: true) == "01:01")

        
        
    }
    
    func testPowerFormatter() throws {

        XCTAssert(powerFormatter(watts: 10) == "10 W")
        
    }
    
    
    
    func testHeartRateFormatter() throws {
        
        XCTAssert(heartRateFormatter(heartRate: 10) == "10")
        
    }

    func testCadenceFormatter() throws {
        
        XCTAssert(cadenceFormatter(cadence: 10) == "10")
        
    }

    func testEnergyFormatter() throws {
        
        XCTAssert(energyFormatter(energy: 10) == "10 kcal")
        
    }


}
