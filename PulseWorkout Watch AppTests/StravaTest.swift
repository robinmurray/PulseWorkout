//
//  StravaTest.swift
//  PulseWorkout Watch AppTests
//
//  Created by Robin Murray on 23/10/2024.
//

import XCTest
import StravaSwift

final class StravaTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
        
        let config = StravaConfig(
            clientId: 138595,
            clientSecret: "86ff0c43b3bdaddc87264a2b85937237639a1ac9",
            redirectUri: "https://github.com/robinmurray/PulseWorkout",
            scopes: [.activityReadAll, .activityWrite]
        )

        let strava = StravaClient.sharedInstance.initWithConfig(config)

        strava.author
        print("Starting strava.request")
        strava.request(Router.athletes(id: 9999999, params: [:]),
                       result: { (athlete: Athlete?) in
            
            print("Success! athlete \(String(describing: athlete))")
            //do something with the athlete
        },
                       failure: { print("failure \($0)") } )
        print("waiting...")
        sleep(10)
        print("waited")
        
//        StravaClient.sharedInstance.request(Router.athlete, result: {print("Success")}, failure: {print("Failure")})

/*
        strava.authorize() { result in
            switch result {
                case .success(let token):
                    //do something for success
                    print("Success!!")
                case .failure(let error):
                    //do something for error
                    print("failure \(error)")
            }
        }
 */
        

    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
