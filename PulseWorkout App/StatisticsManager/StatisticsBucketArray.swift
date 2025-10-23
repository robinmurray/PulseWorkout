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
        
        let bucketStartDates = getBucketStartDates()
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MM yyyy HH:mm:ss"
        
        for bucketType in BucketType.allCases {
            
            for count in 0..<StatisticsBucketCount[bucketType]! {
                
                if let bucketDate = Calendar.current.date(byAdding: StatisticsBucketDuration[bucketType]!.unit,
                                                          value: -1 * count * StatisticsBucketDuration[bucketType]!.count,
                                                          to: bucketStartDates[bucketType]!) {

                    if let index = elements.firstIndex(where: {(formatter.string(from: $0.startDate) == formatter.string(from: bucketDate)) &&
                        ( $0.bucketType == bucketType.rawValue)} ) {

                        elements[index].setId(index: count)     // Set the bucket's Id to new position
                        tempBuckets.append(elements[index])
                    }
                    else {
                        tempBuckets.append(StatisticsBucket(startDate: bucketDate,
                                                            bucketType: bucketType,
                                                            index: count))
                    }
                }
                
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
    
    

    
    func getBucketStartDates() -> [BucketType: Date] {
        
        var todayComponents = Calendar.current.dateComponents([.day, .year, .month], from: Date.now)
        todayComponents.timeZone = .gmt
        let today = Calendar.current.date(from: todayComponents)!

        var weekComponents = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date.now)
        weekComponents.timeZone = .gmt
        let weekStart = Calendar.current.date(from: weekComponents)!
        
        var quarterComponents = Calendar.current.dateComponents([.day, .year, .month], from: Date.now)
        quarterComponents.timeZone = .gmt
        quarterComponents.day = 1
        quarterComponents.month = (((quarterComponents.month! - 1) / 3) * 3) + 1
        let quarterStart = Calendar.current.date(from: quarterComponents)!
        
        var yearComponents  = Calendar.current.dateComponents([.day, .year, .month], from: Date.now)
        yearComponents.timeZone = .gmt
        yearComponents.day = 1
        yearComponents.month = 1
        let yearStart = Calendar.current.date(from: yearComponents)!

        
        let bucketStartDates: [BucketType: Date] = [.day: today,
                                                    .week: weekStart,
                                                    .quarter: quarterStart,
                                                    .year: yearStart]
        
        return bucketStartDates
    }
    
    
    /// Create a set of empty buckets
    func emptyTempBuckets() {
        
        tempBuckets = []
        
        let bucketStartDates = getBucketStartDates()
        
        for bucketType in BucketType.allCases {
            
            for count in 0..<StatisticsBucketCount[bucketType]! {
                
                if let bucketDate = Calendar.current.date(byAdding: StatisticsBucketDuration[bucketType]!.unit,
                                                          value: -1 * count * StatisticsBucketDuration[bucketType]!.count,
                                                          to: bucketStartDates[bucketType]!) {
 
                    tempBuckets.append(StatisticsBucket(startDate: bucketDate,
                                                        bucketType: bucketType,
                                                        index: count))

                }
                
            }
        }
        
        logger.info("Empty buckets \(self.tempBuckets)")

    }
    
    
    /// Add activity to elements
    func addActivity(_ activityRecord: ActivityRecord) {
        
        shuffleForwardIfNecessary()

        for (index, bucket) in elements.enumerated() {
            let activityDate = stringToDate(dateString: dateAsString(date: activityRecord.startDateLocal))
            let bucketStartDate = stringToDate(dateString: bucket.startDateString)
            let bucketEndDate = stringToDate(dateString: bucket.endDateString)
            
            if (activityDate >= bucketStartDate) && (activityDate < bucketEndDate) {
                elements[index].activities += 1
                elements[index].distanceMeters += activityRecord.distanceMeters
                elements[index].addTypedValues(newWorkoutTypeIds: [activityRecord.workoutTypeId],
                                               newActivities: [1],
                                               newDistanceMeters: [activityRecord.distanceMeters])

                elements[index].time += activityRecord.movingTime
                elements[index].TSS +=  activityRecord.TSSorEstimate()

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
            let activityDate = stringToDate(dateString: dateAsString(date: activityRecord.startDateLocal))
            let bucketStartDate = stringToDate(dateString: bucket.startDateString)
            let bucketEndDate = stringToDate(dateString: bucket.endDateString)
            
            if (activityDate >= bucketStartDate) && (activityDate < bucketEndDate) {
                elements[index].activities = max(0, elements[index].activities - 1)
                elements[index].distanceMeters = max(0, elements[index].distanceMeters - activityRecord.distanceMeters)
                elements[index].removeTypedValues(workoutTypeIds: [activityRecord.workoutTypeId],
                                                  activities: [1],
                                                  distanceMeters: [activityRecord.distanceMeters])

                elements[index].time = max(0, elements[index].time - activityRecord.movingTime)
                elements[index].TSS = max(0, elements[index].TSS - activityRecord.TSSorEstimate())

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
            let activityDate = stringToDate(dateString: dateAsString(date: activityRecord.startDateLocal))
            let bucketStartDate = stringToDate(dateString: bucket.startDateString)
            let bucketEndDate = stringToDate(dateString: bucket.endDateString)
            
            if (activityDate >= bucketStartDate) && (activityDate < bucketEndDate) {
                tempBuckets[index].activities += 1
                tempBuckets[index].distanceMeters += activityRecord.distanceMeters
                tempBuckets[index].addTypedValues(newWorkoutTypeIds: [activityRecord.workoutTypeId],
                                                  newActivities: [1],
                                                  newDistanceMeters: [activityRecord.distanceMeters])

                tempBuckets[index].time += activityRecord.movingTime
                tempBuckets[index].TSS += activityRecord.TSSorEstimate()
                
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
  
    
    func dateAsString(date: Date) -> String {
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        dateFormatter.timeZone = .current
        return date.formatted(.iso8601
            .year()
            .month()
            .day())
        
    }
    
    func stringToDate(dateString: String) -> Date {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate] // Added format options
        let date = dateFormatter.date(from: dateString) ?? Date.now
        return date
    }
    
    
    func thisWeekStartDate() -> Date {
        
        var weekComponents = Calendar.current.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: Date.now)
        weekComponents.timeZone = .gmt
        let weekStart = Calendar.current.date(from: weekComponents)!
        
        // return dateAsString(date: weekStart)
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
            .filter( {stringToDate(dateString: $0.startDateString) >= thisWeekStartDate()})
        
        logger.info("thisWeekDayBuckets \(buckets)")
        return StatisticsBucketArray(elements: buckets)
    }

    
    func lastWeekDayBuckets() -> StatisticsBucketArray {
        
        let buckets = getBucketsByType(bucketType: .day).elements
            .filter( {stringToDate(dateString: $0.startDateString) >= lastWeekStartDate()})
            .filter( {stringToDate(dateString: $0.startDateString) < thisWeekStartDate()})
        
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
        fullList.setAsWeeklyAverage(divisorDays: divisorDaysForWeeklyAverage())
        return fullList
        
    }
    
    func asYearStackedBarChartData(propertyName: String, filterList: [String] = []) -> StackedBarChartData {
        
        var fullList = asStackedBarChartData(propertyName: propertyName,
                                             indexNames: ["last", "this"])
        
        // If filterList set then reduce stacked bar data just to those categories
        if filterList.count > 0 {
            fullList = StackedBarChartData(copyFrom: fullList, filterCategories: filterList)
        }
        fullList.setAsWeeklyAverage(divisorDays: divisorDaysForWeeklyAverage())
        return fullList
        
    }
    
    
    func divisorDaysForWeeklyAverage() -> Double {

        var divisor: Double = 1
        
        if let endDate = elements.last?.endDate,
           let startDate = elements.filter({$0.activities > 0}).first?.startDate
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
        chartData.setAsWeeklyAverage(divisorDays: divisorDaysForWeeklyAverage())
        return chartData
        
    }
  
}

