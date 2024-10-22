//
//  DataCacheTest.swift
//  PulseWorkout Watch AppTests
//
//  Created by Robin Murray on 19/10/2024.
//

import XCTest

@testable import PulseWorkout_Watch_App

final class DataCacheTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFullActivityRecordCache() throws {

        let fullActivityRecordCache = FullActivityRecordCache()
        let settingsManager = SettingsManager()
        
        var activityRecords: [ActivityRecord] = []
        
        for _ in (0...5) {
            activityRecords.append(ActivityRecord(settingsManager: settingsManager))
        }

        XCTAssert(fullActivityRecordCache.get(recordID: activityRecords[0].recordID) == nil)
        fullActivityRecordCache.add(activityRecord: activityRecords[0])
        XCTAssert(fullActivityRecordCache.get(recordID: activityRecords[0].recordID) == activityRecords[0])
        fullActivityRecordCache.add(activityRecord: activityRecords[1])
        XCTAssert(fullActivityRecordCache.get(recordID: activityRecords[0].recordID) == activityRecords[0])
        XCTAssert(fullActivityRecordCache.get(recordID: activityRecords[1].recordID) == activityRecords[1])

        fullActivityRecordCache.add(activityRecord: activityRecords[2])
        fullActivityRecordCache.add(activityRecord: activityRecords[3])
        fullActivityRecordCache.add(activityRecord: activityRecords[4])

        XCTAssert(fullActivityRecordCache.get(recordID: activityRecords[0].recordID) == activityRecords[0])
        XCTAssert(fullActivityRecordCache.get(recordID: activityRecords[1].recordID) == activityRecords[1])
        XCTAssert(fullActivityRecordCache.get(recordID: activityRecords[2].recordID) == activityRecords[2])
        XCTAssert(fullActivityRecordCache.get(recordID: activityRecords[3].recordID) == activityRecords[3])
        XCTAssert(fullActivityRecordCache.get(recordID: activityRecords[4].recordID) == activityRecords[4])

        fullActivityRecordCache.add(activityRecord: activityRecords[5])
        XCTAssert(fullActivityRecordCache.get(recordID: activityRecords[0].recordID) == nil)

        // Test reelase least-recently used...
        fullActivityRecordCache.add(activityRecord: activityRecords[0])
        XCTAssert(fullActivityRecordCache.get(recordID: activityRecords[0].recordID) == activityRecords[0])
        XCTAssert(fullActivityRecordCache.get(recordID: activityRecords[1].recordID) == nil)
        XCTAssert(fullActivityRecordCache.get(recordID: activityRecords[2].recordID) == activityRecords[2])

        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
