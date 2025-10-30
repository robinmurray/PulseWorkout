//
//  StatisticsBucketArray.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 22/06/2025.
//

import Foundation
import os
import CloudKit





class StatisticsBucketArray: NSObject, Codable {
    
    let cacheFile = "statisticsCache.json"
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "statisticsBucketArray")
    
    var elements: [StatisticsBucket] = []
    private var tempBuckets: [StatisticsBucket] = []
    
    // set CodingKeys to define which variables are stored to JSON file
    private enum CodingKeys: String, CodingKey {
        case elements
    }
    
    init(elements: [StatisticsBucket]) {
        
        self.elements = elements
        
    }
    
    override init() {
        super.init()
        _ = read()
        
        shuffleForwardIfNecessary()

    }
   
    /// Shuffle current data in bukets forward to match current date IF needed
    func shuffleForwardIfNecessary() {
        if requireShuffling() {
            shuffleForward()
        }
    }
    
    /// Shuffle current data in bukets forward to match current date
    private func shuffleForward() {
       
        tempBuckets = []
        
        logger.info("Shuffling stats buckets forward")
        for bucketType in BucketType.allCases {
            
            for count in 0..<StatisticsBucketCount[bucketType]! {
                
                let (startDate, endDate) = getBucketStartAndEndDates(bucketType: bucketType, bucketIndex: count)
                
                if let index = elements.firstIndex(where: {($0.startDate == startDate) &&
                    ( $0.bucketType == bucketType.rawValue)} ) {

                    elements[index].setId(index: count)     // Set the bucket's Id to new position
                    tempBuckets.append(elements[index])
                }
                else {
                    tempBuckets.append(StatisticsBucket(startDate: startDate,
                                                        endDate: endDate,
                                                        bucketType: bucketType,
                                                        index: count))
                }

/*
                
                if let bucketDate = Calendar.current.date(byAdding: StatisticsBucketDuration[bucketType]!.unit,
                                                                          value: -1 * count * StatisticsBucketDuration[bucketType]!.count,
                                                                          to: bucketStartDates[bucketType]!) {
                    let GMTBucketDate = bucketDate.addingTimeInterval(TimeInterval(Calendar.current.timeZone.secondsFromGMT(for: bucketDate)))
                    let nonGMTEndDate = Calendar.current.date(byAdding: StatisticsBucketDuration[bucketType]!.unit,
                                                                         value: StatisticsBucketDuration[bucketType]!.count,
                                                                         to: GMTBucketDate)!
                    let GMTEndDate = nonGMTEndDate.addingTimeInterval(TimeInterval(Calendar.current.timeZone.secondsFromGMT(for: nonGMTEndDate)) -
                                                                    TimeInterval(Calendar.current.timeZone.secondsFromGMT(for: GMTBucketDate)))

                    if let index = elements.firstIndex(where: {($0.startDate == GMTBucketDate) &&
                        ( $0.bucketType == bucketType.rawValue)} ) {

                        elements[index].setId(index: count)     // Set the bucket's Id to new position
                        tempBuckets.append(elements[index])
                    }
                    else {
                        tempBuckets.append(StatisticsBucket(startDate: GMTBucketDate,
                                                            endDate: GMTEndDate,
                                                            bucketType: bucketType,
                                                            index: count))
                    }
                }
               */
            }
        }
        
        elements = tempBuckets

        _ = write()
    }
    
    
    /// returns true if the bucket array needs to be shuffled forward because curent date is after the latest day bucket
    private func requireShuffling() -> Bool {

        var todayComponents = Calendar.current.dateComponents([.day, .year, .month], from: Date.now)
        todayComponents.timeZone = .gmt
        let today = Calendar.current.date(from: todayComponents)!

        if let _ = elements.first(where: {
            ($0.bucketType == BucketType.day.rawValue) &&
            ($0.startDate >= today)}) {
            return false
        }
        return true
    }
    
    
    
    /// Return current timezone version of first bucket start date for a bucket type
    func getFirstBucketStartDate(bucketType: BucketType) -> Date {
        
        switch bucketType {
        case .day:
            var startDateComponents = Calendar.current.dateComponents([.day, .year, .month], from: Date.now)
            startDateComponents.timeZone = .current
            return Calendar.current.date(from: startDateComponents)!
            
        case .week:
            var startDateComponents = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date.now)
            startDateComponents.timeZone = .current
            return Calendar.current.date(from: startDateComponents)!
            
        case .quarter:
            var startDateComponents = Calendar.current.dateComponents([.day, .year, .month], from: Date.now)
            startDateComponents.timeZone = .current
            startDateComponents.day = 1
            startDateComponents.month = (((startDateComponents.month! - 1) / 3) * 3) + 1
            return Calendar.current.date(from: startDateComponents)!
            
        case .year:
            var startDateComponents  = Calendar.current.dateComponents([.day, .year, .month], from: Date.now)
            startDateComponents.timeZone = .current
            startDateComponents.day = 1
            startDateComponents.month = 1
            return Calendar.current.date(from: startDateComponents)!
        }
    }
    
    
    /// Return GMT versions of startDate and endDate for a bucket of a given type and index from zero
    func getBucketStartAndEndDates(bucketType: BucketType, bucketIndex: Int) -> (Date, Date) {
        
        // Get non-GMT version of first bucket start date
        let firstNonGMTBucketStartDate = getFirstBucketStartDate(bucketType: bucketType)
        
        let nonGMTBucketStartDate = Calendar.current.date(byAdding: StatisticsBucketDuration[bucketType]!.unit,
                                                          value: -1 * bucketIndex * StatisticsBucketDuration[bucketType]!.count,
                                                          to: firstNonGMTBucketStartDate)!
        
        let nonGMTBucketEndDate = Calendar.current.date(byAdding: StatisticsBucketDuration[bucketType]!.unit,
                                                        value: StatisticsBucketDuration[bucketType]!.count,
                                                        to: nonGMTBucketStartDate)!
        
        let GMTBucketStartDate = nonGMTBucketStartDate.addingTimeInterval(
            TimeInterval(Calendar.current.timeZone.secondsFromGMT(for: nonGMTBucketStartDate)))
        
        let GMTBucketEndDate = nonGMTBucketEndDate.addingTimeInterval(
            TimeInterval(Calendar.current.timeZone.secondsFromGMT(for: nonGMTBucketEndDate)))
        
        return (GMTBucketStartDate, GMTBucketEndDate)

    }
    
    /// Create a set of empty buckets
    func emptyTempBuckets() {
        
        tempBuckets = []
        
        for bucketType in BucketType.allCases {
            
            for count in 0..<StatisticsBucketCount[bucketType]! {
                
                let (startDate, endDate) = getBucketStartAndEndDates(bucketType: bucketType, bucketIndex: count)
                tempBuckets.append(StatisticsBucket(startDate: startDate,
                                                    endDate: endDate,
                                                    bucketType: bucketType,
                                                    index: count))
                
                /*
                if let bucketDate = Calendar.current.date(byAdding: StatisticsBucketDuration[bucketType]!.unit,
                                                          value: -1 * count * StatisticsBucketDuration[bucketType]!.count,
                                                          to: bucketStartDates[bucketType]!) {
                    let GMTBucketDate = bucketDate.addingTimeInterval(TimeInterval(Calendar.current.timeZone.secondsFromGMT(for: bucketDate)))
                    let nonGMTEndDate = Calendar.current.date(byAdding: StatisticsBucketDuration[bucketType]!.unit,
                                                                         value: StatisticsBucketDuration[bucketType]!.count,
                                                                         to: GMTBucketDate)!
                    let GMTEndDate = nonGMTEndDate.addingTimeInterval(TimeInterval(Calendar.current.timeZone.secondsFromGMT(for: nonGMTEndDate)) -
                                                                    TimeInterval(Calendar.current.timeZone.secondsFromGMT(for: GMTBucketDate)))
                    tempBuckets.append(StatisticsBucket(startDate: GMTBucketDate,
                                                        endDate: GMTEndDate,
                                                        bucketType: bucketType,
                                                        index: count))

                }
                 */
                
            }
        }
        
        logger.info("Empty buckets \(self.tempBuckets)")

    }
    
    
    /// Add activity to elements
    func addActivity(_ activityRecord: ActivityRecord) {
        
        shuffleForwardIfNecessary()

        for (index, bucket) in elements.enumerated() {
            
            if (activityRecord.startDateLocal >= bucket.startDate) && (activityRecord.startDateLocal < bucket.endDate) {
                elements[index].activities += 1
                elements[index].distanceMeters = round(elements[index].distanceMeters + activityRecord.distanceMeters)
                elements[index].addTypedValues(newWorkoutTypeIds: [activityRecord.workoutTypeId],
                                               newActivities: [1],
                                               newDistanceMeters: [round(activityRecord.distanceMeters)])

                elements[index].time = round(elements[index].time + activityRecord.movingTime)

                elements[index].TSS +=  activityRecord.TSSorEstimate()
                elements[index].TSS = round(elements[index].TSS * 10) / 10
                // Add range-ified TSS by power zone array
                elements[index].TSSByZone = zip(elements[index].TSSByZone,
                                                activityRecord.TSSbyRangeFromZone()).map(+)
                    .map( {round($0 * 10) / 10} )
                

                
                // Add range-ified moving time by HR zone array
                elements[index].timeByZone = zip(elements[index].timeByZone,
                                                  activityRecord.movingTimebyRangeFromZone()).map(+)
                    .map( {round($0 * 10) / 10} )
                                
            }
        }
    }
    
    
    /// Remove activity from elements
    func removeActivity(_ activityRecord: ActivityRecord) {

        print("Removing activity from buckets")
        
        shuffleForwardIfNecessary()
        
        for (index, bucket) in elements.enumerated() {
            
            if (activityRecord.startDateLocal >= bucket.startDate) && (activityRecord.startDateLocal < bucket.endDate) {
                elements[index].activities = max(0, elements[index].activities - 1)
                elements[index].distanceMeters = round(max(0, elements[index].distanceMeters - activityRecord.distanceMeters))
                elements[index].removeTypedValues(workoutTypeIds: [activityRecord.workoutTypeId],
                                                  activities: [1],
                                                  distanceMeters: [round(activityRecord.distanceMeters)])

                elements[index].time = round(max(0, elements[index].time - activityRecord.movingTime))
                elements[index].TSS = round(max(0, elements[index].TSS - activityRecord.TSSorEstimate()) * 10) / 10

                // Add range-ified TSS by power zone array
                elements[index].TSSByZone = zip(elements[index].TSSByZone,
                                                activityRecord.TSSbyRangeFromZone()).map({max(0, $0 - $1)})
                    .map( {round($0 * 10) / 10} )
                

                
                // Add range-ified moving time by HR zone array
                elements[index].timeByZone = zip(elements[index].timeByZone,
                                                 activityRecord.movingTimebyRangeFromZone()).map({max(0, $0 - $1)})
                    .map( {round($0 * 10) / 10} )
                                
            }
        }
    }
    
    
    func addActivityToTemp(_ activityRecord: ActivityRecord) {

        for (index, bucket) in tempBuckets.enumerated() {
            
            if (activityRecord.startDateLocal >= bucket.startDate) && (activityRecord.startDateLocal < bucket.endDate) {
                tempBuckets[index].activities += 1
                tempBuckets[index].distanceMeters = round(tempBuckets[index].distanceMeters + activityRecord.distanceMeters)

                tempBuckets[index].addTypedValues(newWorkoutTypeIds: [activityRecord.workoutTypeId],
                                                  newActivities: [1],
                                                  newDistanceMeters: [round(activityRecord.distanceMeters)])

                tempBuckets[index].time = round(tempBuckets[index].time + activityRecord.movingTime)

                tempBuckets[index].TSS += activityRecord.TSSorEstimate()
                tempBuckets[index].TSS = round(tempBuckets[index].TSS * 10) / 10

                // Add range-ified TSS by power zone array
                tempBuckets[index].TSSByZone = zip(tempBuckets[index].TSSByZone,
                                                   activityRecord.TSSbyRangeFromZone()).map(+)
                    .map( {round($0 * 10) / 10} )

                
                // Add range-ified moving time by HR zone array
                tempBuckets[index].timeByZone = zip(tempBuckets[index].timeByZone,
                                                    activityRecord.movingTimebyRangeFromZone()).map(+)
                    .map( {round($0 * 10) / 10} )
                
                
            }
        }
        
    }
    
    func copyTempToElements() {
        elements = tempBuckets
        logger.info("Buckets = \(self.elements)")
    }
    
    /// Read cache from JSON file in cache folder
    private func read() -> Bool {

        guard let cacheURL = CacheURL(fileName: cacheFile) else { return false }

        do {
            let data = try Data(contentsOf: cacheURL)
            let decoder = JSONDecoder()
            let JSONData = try decoder.decode(StatisticsBucketArray.self, from: data)
            elements = JSONData.elements

            logger.info("elements returned from cache: \(self.elements)")
            return true
        }
        catch {
            logger.error("error:\(error.localizedDescription)")
            return false
        }
    }
    
    
    /// Write bucket array to cache as JSON file
    func write(copyToCK: Bool = true) -> Bool  {
        
        guard let cacheURL = CacheURL(fileName: cacheFile) else { return false}
        
        logger.log("Writing statistics cache to JSON file")

        do {
            let data = try JSONEncoder().encode(self)

            do {
                try data.write(to: cacheURL)

                // TEST...
                if copyToCK {
                    writeToCK()
                }

                return true
            }
            catch {
                logger.error("error \(error.localizedDescription)")
                return false
            }

        } catch {
            logger.error("Error enconding statistics cache")
            return false
        }

    }
    
    func asCKRecords() -> [CKRecord] {
        return elements.map{ $0.asCKRecord() }
    }
    
    /// Write bucket array to cloudkit
    func writeToCK() {
        
        CKBlockSaveAndDeleteOperation(recordsToSave: asCKRecords(),
                                      recordIDsToDelete: []).execute()
                                      
    }
    
   
    /// On block completion copy temporary list to the main device list
    func createElementsFromCKRecords(ckRecordList: [CKRecord]) -> Void {
        
        elements = ckRecordList.map( {StatisticsBucket(fromCKRecord: $0)})
        
        // Write to JSON file - Don't write back to CK!!
        _ = write(copyToCK: false)
        
        shuffleForwardIfNecessary()

    }
    
    
    func thisWeekStartDate() -> Date {
        
        var weekComponents = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date.now)
        weekComponents.timeZone = .gmt
        let weekStart = Calendar.current.date(from: weekComponents)!
        
        return weekStart
        
    }

    func lastWeekStartDate() -> Date {
        
        let weekAgo = Calendar.current.date(byAdding: .day,
                                            value: -7,
                                            to: Date.now)!
        var weekComponents = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: weekAgo)
        weekComponents.timeZone = .gmt
        let weekStart = Calendar.current.date(from: weekComponents)!
        return weekStart
        
    }

    
    func getBucketsByType(bucketType: BucketType) -> StatisticsBucketArray {
        
        let buckets = elements.filter({ $0.bucketType == bucketType.rawValue })
            .sorted { itemA, itemB in
                itemA.startDate < itemB.startDate
            }

        return StatisticsBucketArray(elements: buckets)
    }
    
    
    func yearBuckets() -> StatisticsBucketArray {
        return getBucketsByType(bucketType: .year)
    }
    
    
    func quarterBuckets() -> StatisticsBucketArray {
        return getBucketsByType(bucketType: .quarter)
    }
    
    
    func weekBuckets() -> StatisticsBucketArray {
        return getBucketsByType(bucketType: .week)
    }

    
    func thisWeekDayBuckets() -> StatisticsBucketArray {
        
        let buckets = getBucketsByType(bucketType: .day).elements
            .filter( {$0.startDate >= thisWeekStartDate()})
        
        logger.info("thisWeekDayBuckets \(buckets)")
        return StatisticsBucketArray(elements: buckets)
    }

    
    func lastWeekDayBuckets() -> StatisticsBucketArray {
        
        let buckets = getBucketsByType(bucketType: .day).elements
            .filter( {$0.startDate >= lastWeekStartDate()})
            .filter( {$0.startDate < thisWeekStartDate()})
        
        return StatisticsBucketArray(elements: buckets)
    }
    

    func asStackedBarChartData(propertyName: String, indexNames: [String]) -> StackedBarChartData { // NEED TO PASS OR GET CATEGORY PROPERTY NAME!
 
        var stackedBarChartData: StackedBarChartData = StackedBarChartData(propertyName: propertyName)
        
        let byZonePropertyName = PropertyViewParamaters[propertyName]?.byZonePropertyName ?? propertyName
                
        for (i, indexName) in indexNames.enumerated() {
            if i < elements.count {
                /*if let value = elements[i].asCKRecord()[propertyName] as? Double {
                    stackedBarChartData.add(category: indexName, subCategory: 0, value: value)

                } else */ if let array = elements[i].asCKRecord()[byZonePropertyName] as? [Double] {
                    if array.count > 0 {
                        for (catIndex, value) in array.enumerated() {
                            switch stackedBarChartData.stackedBarType {
                            case .powerZone:
                                stackedBarChartData.add(category: indexName,
                                                        subCategory: catIndex,
                                                        value: value)
                            case .activityType:
                                stackedBarChartData.add(category: indexName,
                                                        subCategory: Int(elements[i].workoutTypeIds[catIndex]),
                                                        value: value)
                            }

                        }
                    }
                    else {
                        stackedBarChartData.add(category: indexName,
                                                subCategory: nil,
                                                value: 0)
                   }

                }
            }
            else {
                stackedBarChartData.add(category: indexName,
                                        subCategory: nil,
                                        value: 0)
           }
       }
       
       return stackedBarChartData
    }
    
    
   
    
    func asDayOfWeekStackedBarChartData(propertyName: String) -> StackedBarChartData {
        
        return asStackedBarChartData(propertyName: propertyName, indexNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
        
    }
    
    func asWeekStackedBarChartData(propertyName: String, filterList: [String] = []) -> StackedBarChartData {
        
        var fullList = asStackedBarChartData(propertyName: propertyName,
                                             indexNames: ["-11", "-10", "-9", "-8", "-7", "-6", "-5", "-4", "-3", "-2", "last", "this"])
        
        // If filterList set then reduce stacked bar data just to those categories
        if filterList.count > 0 {
            fullList = StackedBarChartData(copyFrom: fullList, filterCategories: filterList)
        }
        fullList.setAsWeeklyAverage(divisorDays: divisorDaysForWeeklyAverage(buckets: elements.filter({$0.bucketType == BucketType.week.rawValue})))
        return fullList
        
    }
    
    func asYearStackedBarChartData(propertyName: String, filterList: [String] = []) -> StackedBarChartData {
        
        let indexNames = ["last", "this"]
        var fullList = asStackedBarChartData(propertyName: propertyName,
                                             indexNames: indexNames)
        var bucketList = elements.filter({$0.bucketType == BucketType.year.rawValue})
        
        // If filterList set then reduce stacked bar data just to those categories
        if filterList.count > 0 {
            let filterIndices = filterList.map({filterListItem in indexNames.firstIndex(where: {$0 == filterListItem}) ?? 0})
            bucketList = filterIndices.map( {bucketList[$0]} )
            fullList = StackedBarChartData(copyFrom: fullList, filterCategories: filterList)

        }
        fullList.setAsWeeklyAverage(divisorDays: divisorDaysForWeeklyAverage(buckets: bucketList))
        return fullList
        
    }
    
    
    func divisorDaysForWeeklyAverage(buckets: [StatisticsBucket]) -> Double {

        var divisor: Double = 1
        
        if let endDate = buckets.last?.endDate,
           let startDate = buckets.filter({$0.activities > 0}).first?.startDate
        {
            let days: Int = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1
            let daysToNow = Calendar.current.dateComponents([.day], from: startDate, to: Date.now).day ?? 1
            let divisorDays = max(min(days, daysToNow), 1)
            divisor = Double(divisorDays) / 7

        }
        
        return divisor
    }
    
    func asQuarterStackedBarChartData(propertyName: String) -> StackedBarChartData {
        
        var chartData = asStackedBarChartData(propertyName: propertyName, indexNames: ["-3", "-2", "-1", "this"])
        chartData.setAsWeeklyAverage(divisorDays: divisorDaysForWeeklyAverage(buckets: elements.filter({$0.bucketType == BucketType.quarter.rawValue})))
        return chartData
        
    }
  
}

