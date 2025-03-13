//
//  ImageCacheTest.swift
//  PulseWorkout Phone AppTests
//
//  Created by Robin Murray on 27/12/2024.
//

import XCTest

final class ImageCacheTest: XCTestCase {

    var dataCache: DataCache
    let settingsManager: SettingsManager = SettingsManager.shared
    var imageCache: ImageCache?
    
    override init() {

        dataCache = DataCache(testMode: true)
        
        super.init()
    }

    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
 //       imageCache = ImageCache(dataCache: dataCache, testMode: true)
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
        
        let imageData = UIImage(systemName: "tray.full")?.jpegData(compressionQuality: 0.5)
        let activityRecord = ActivityRecord()
        imageCache = ImageCache(dataCache: dataCache, testMode: true)

        XCTAssert(imageCache?.getImage(record: activityRecord, imageType: .mapSnapshot) == nil)
        
        // activityRecord is not in main cache, so should not add image
        imageCache?.add(record: activityRecord, image: imageData!, imageType: .mapSnapshot)
        XCTAssert(imageCache?.getImage(record: activityRecord, imageType: .mapSnapshot) == nil)
        
//        dataCache.add(activityRecord: activityRecord)
        // activityRecord IS in main cache, so should add image
//        imageCache?.add(record: activityRecord, image: imageData!)
//        XCTAssert(imageCache?.getImage(record: activityRecord) == UIImage(data: imageData!))

        
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
