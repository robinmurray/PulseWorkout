//
//  PulseWorkout_Watch_AppTests.swift
//  PulseWorkout Watch AppTests
//
//  Created by Robin Murray on 21/12/2022.
//

import XCTest
@testable import PulseWorkout_Watch_App

final class PulseWorkout_Watch_AppTests: XCTestCase {

    var dataCache: DataCache = DataCache(readCache: false)
    var settingsManager: SettingsManager?
    var dummyActivityRecord: ActivityRecord?
    

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        settingsManager = SettingsManager()
        dummyActivityRecord = ActivityRecord(settingsManager: settingsManager!)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Tests marked async will run the test method on an arbitrary thread managed by the Swift runtime.
    }
    
    func testtoBeSaved() throws {
        
        XCTAssert(dataCache.toBeSaved() == [],
                  "to-be-saved list is not empty - len \(dataCache.toBeSaved().count)")
        
        dataCache.add(activityRecord: dummyActivityRecord!)

        XCTAssert(dataCache.toBeSaved().count == 1,
                  "to-be-saved list is not correct - len \(dataCache.toBeSaved().count)")

        dataCache.delete(recordID: dummyActivityRecord!.recordID!)

        XCTAssert(dataCache.toBeSaved() == [],
                  "to-be-saved list is not empty - len \(dataCache.toBeSaved().count)")

        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
