//
//  ActivityRecordTest.swift
//  PulseWorkout Watch AppTests
//
//  Created by Robin Murray on 05/12/2023.
//

import XCTest
@testable import PulseWorkout_Watch_App

public func differenceBetweenStrings(s1: String, s2: String) -> String {
    let len1 = s1.count
    let len2 = s2.count
    let c1 = Array(s1)
    let c2 = Array(s2)
    let lenMin = min(len1, len2)
    

    for i in 0..<lenMin {
        if c1[i] != c2[i] {
            let substring = c1[...i]
            return "Difference index \(i), value \(c1[i]) vs \(c2[i]) substring \(substring)"
        }
    }
    
    if len1 < len2 {
        return "String 1 shorter by \(len2 - len1)"
    }

    if len2 < len1 {
        return "String 1 shorter by \(len1 - len2)"
    }

    return "Equal"
}

final class ActivityRecordTest: XCTestCase {

    let settingsManager = SettingsManager.shared
    var activityRecord: ActivityRecord!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        activityRecord = ActivityRecord()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAnalysedVariable() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.

        settingsManager.aveHRPaused = false
        settingsManager.aveCadenceZeros = false
        settingsManager.avePowerZeros = false
        
        activityRecord.set(heartRate: 1)
        activityRecord.set(watts: 10)
        activityRecord.set(cadence: 20)
        activityRecord.addTrackPoint()

        activityRecord.set(heartRate: 2)
        activityRecord.set(watts: 20)
        activityRecord.set(cadence: 40)
        activityRecord.addTrackPoint()

        activityRecord.set(heartRate: 3)
        activityRecord.set(watts: 30)
        activityRecord.set(cadence: 60)
        activityRecord.addTrackPoint()
        
        XCTAssert(activityRecord.heartRate == 3,
                  "heart rate not correct")
        XCTAssert(activityRecord.heartRateAnalysis.average == 2,
                  "average heart rate not correct")
        XCTAssert(activityRecord.heartRateAnalysis.N == 3,
                  "heart rate count not correct")
        XCTAssert(activityRecord.heartRateAnalysis.maxVal == 3,
                  "heart rate maximum not correct")

        XCTAssert(activityRecord.powerAnalysis.average == 20,
                  "average power not correct")
        XCTAssert(activityRecord.cadenceAnalysis.average == 40,
                  "average power not correct")
        
        activityRecord.set(isPaused: true)
        XCTAssert(activityRecord.isPaused == true, "isPaused not set correctly")
        activityRecord.set(heartRate: 6)
        activityRecord.set(watts: 0)
        activityRecord.set(cadence: 0)

        activityRecord.addTrackPoint()
        
        XCTAssert(activityRecord.heartRateAnalysis.average == 2,
                  "average heart rate not correct with pause")
        XCTAssert(activityRecord.powerAnalysis.average == 20,
                  "average power not ignoring zeros")
        XCTAssert(activityRecord.cadenceAnalysis.average == 40,
                  "average power not ignoring zeros")

        // test takes account of settings
        settingsManager.aveHRPaused = true
        settingsManager.aveCadenceZeros = true
        settingsManager.avePowerZeros = true

        activityRecord.set(heartRate: 6)
        activityRecord.set(watts: 0)
        activityRecord.set(cadence: 0)

        activityRecord.addTrackPoint()
        
        XCTAssert(activityRecord.heartRateAnalysis.average == 3,
                  "average heart rate not taking account of settings")
        XCTAssert(activityRecord.powerAnalysis.average == 15,
                  "average power ?? ignoring zeros")
        XCTAssert(activityRecord.cadenceAnalysis.average == 30,
                  "average power ?? ignoring zeros")
    }

    func testDistanceTime() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.

       
        activityRecord.set(elapsedTime: 10)

        XCTAssert(activityRecord.averageSpeed == 0,
                  "ave speed not correct with zero distance")
        
        activityRecord.set(distanceMeters: 100)
        XCTAssert(activityRecord.averageSpeed == 10,
                  "ave speed not correct with non-zero distance")

        activityRecord.increment(pausedTime: 5)
        activityRecord.set(elapsedTime: 10)
        XCTAssert(activityRecord.averageSpeed == 20,
                  "ave speed not correct with paused time (actual \(activityRecord.averageSpeed))")

        activityRecord.increment(pausedTime: 4)
        activityRecord.set(elapsedTime: 10)
        XCTAssert(activityRecord.averageSpeed == 100,
                  "ave speed not correct with incremented paused time (actual \(activityRecord.averageSpeed))")

        activityRecord.increment(pausedTime: 1)
        activityRecord.set(elapsedTime: 10)
        XCTAssert(activityRecord.averageSpeed == 0,
                  "ave speed not correct with zero time (actual \(activityRecord.averageSpeed))")
        
        activityRecord.increment(pausedTime: 1)
        activityRecord.set(elapsedTime: 10)
        XCTAssert(activityRecord.movingTime == 0,
                  "movingTime not correct with large pause time")
        
        activityRecord.set(elapsedTime: 12)
        XCTAssert(activityRecord.movingTime == 1,
                  "movingTime not correct when pause time wraps")
    }

    func testXML() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.

       
        let XMLOutput = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!-- Written by PulseWorkout -->
        <TrainingCenterDatabase xmlns:ns5="http://www.garmin.com/xmlschemas/ActivityGoals/v1" xsi:schemaLocation="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd" xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2" xmlns:ns2="http://www.garmin.com/xmlschemas/UserProfile/v2" xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
         <Activities>
          <Activity Sport="Biking">
           <Id>2023-04-01T10:00:00Z</Id>
           <Lap StartTime="2023-04-01T10:00:00Z">
            <TotalTimeSeconds>10.0</TotalTimeSeconds>
            <DistanceMeters>100.0</DistanceMeters>
            <AverageHeartRate>
             <Value>0</Value>
            </AverageHeartRate>
            <TriggerMethod>Manual</TriggerMethod>
            <Track>
             <Trackpoint>
              <Time>2023-04-01T10:00:00Z</Time>
              <HeartRateBpm>
               <Value>1</Value>
              </HeartRateBpm>
              <DistanceMeters>100</DistanceMeters>
              <Cadence>20</Cadence>
              <Extensions>
               <TPX xmlns="http://www.garmin.com/xmlschemas/ActivityExtension/v2">
                <Watts>10</Watts>
               </TPX>
              </Extensions>
             </Trackpoint>
            </Track>
           </Lap>
          </Activity>
         </Activities>
        </TrainingCenterDatabase>
        """
        
        let isoDate = "2023-04-01T10:00:00+0000"

        let dateFormatter = ISO8601DateFormatter()
        let date = dateFormatter.date(from:isoDate)!
        
        let activityProfiles = ProfileManager()
        let activityProfile = activityProfiles.newProfile()
        
        activityRecord.start(activityProfile: activityProfile, startDate: date)
        settingsManager.aveHRPaused = false
        settingsManager.aveCadenceZeros = false
        settingsManager.avePowerZeros = false
        
        activityRecord.set(heartRate: 1)
        activityRecord.set(watts: 10)
        activityRecord.set(cadence: 20)
        activityRecord.set(distanceMeters: 100)
        activityRecord.set(elapsedTime: 10)
        
        activityRecord.addTrackPoint(trackPointTime: date)
        
        let XMLDoc = activityRecord.trackRecordXML()
        print(XMLDoc.serialize())

        XCTAssert(XMLDoc.serialize() == XMLOutput, "XML record does not match test. \(differenceBetweenStrings(s1: XMLDoc.serialize(), s2: XMLOutput))")
        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
