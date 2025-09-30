//
//  StatisticsBucketArray.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 22/06/2025.
//

import Foundation
import os
import SwiftUI
import HealthKit

enum StackedBarType {
    case powerZone
    case activityType
}

struct StackedBarChartData {

    struct SubCategory {
        var id: Int
        var label: String
        var color: Color
    }
    struct DataPoint: Identifiable {
        let id = UUID()
        var category: String?
        var subCategory: Int?
        var value: Double
        var formattedValue: String
    }

    
    var propertyName: String
    var subCategories: [SubCategory]
    var dataPoints: [DataPoint]
    
    var totalsByCategory: [DataPoint]           /// Totals for each category - summing across values in subcategories
    var totalsBySubcategory: [DataPoint]        /// Total for each subcategory  - summing across values in categories
    
    var stackedBarType: StackedBarType
    var totalName: String
    var total: Double

    func formattedTotal() -> String {
        return formattedPropertyValue(propertyName, value: total, shortForm: false)
    }
    
    init(propertyName: String) {
        self.propertyName = propertyName
        self.stackedBarType = PropertyViewParamaters[propertyName]?.stackedBarType ?? .powerZone

        dataPoints = []
        subCategories = []
        totalsByCategory = []
        totalsBySubcategory = []
        totalName = PropertyViewParamaters[propertyName]?.totalLabel ?? "Total"
        total = 0

    }
    
    
    // Set the stack data categories for the data in the dataPoints
    mutating func setStackDataCategories() {

        switch stackedBarType {
        case .powerZone:
            subCategories = [SubCategory(id: 0, label: "Low Aerobic", color: .blue),
                             SubCategory(id: 1, label: "High Aerobic", color: .green),
                             SubCategory(id: 2, label: "Anaerobic", color: .orange)]
        case .activityType:
            let uniqueCategories = Set(dataPoints.filter({$0.subCategory != nil}).map({$0.subCategory!})).sorted()
            subCategories = uniqueCategories.map({SubCategory(id: $0,
                                                              label: HKWorkoutActivityType(rawValue: UInt($0))?.name ?? "Error",
                                                              color: HKWorkoutActivityType(rawValue: UInt($0))?.colorRepresentation ?? Color.red)})
        }

    }
    
    
    // Add a datapoint
    mutating func add(category: String, subCategory: Int?, value: Double) {
        dataPoints.append(DataPoint(category: category,
                                    subCategory: subCategory,
                                    value: value,
                                    formattedValue: formattedPropertyValue(propertyName,
                                                                           value: value,
                                                                           shortForm: false)))
        

        if subCategory != nil {
            if let i = totalsBySubcategory.firstIndex(where: {$0.subCategory == subCategory} ) {
                totalsBySubcategory[i].value += value
                totalsBySubcategory[i].formattedValue = formattedPropertyValue(propertyName,
                                                                               value: totalsBySubcategory[i].value,
                                                                               shortForm: false)
            } else {
                totalsBySubcategory.append(DataPoint(subCategory: subCategory,
                                                     value: value,
                                                     formattedValue: formattedPropertyValue(propertyName,
                                                                                            value: value,
                                                                                            shortForm: false)))
            }
            

        }
        

        // Now update category totals
        if let i = totalsByCategory.firstIndex(where: {$0.category == category} ) {
            totalsByCategory[i].value += value
            totalsByCategory[i].formattedValue = formattedPropertyValue(propertyName,
                                                                        value: totalsByCategory[i].value,
                                                                        shortForm: true)
        } else {
            totalsByCategory.append(DataPoint(category: category,
                                              value: value,
                                              formattedValue: formattedPropertyValue(propertyName,
                                                                                     value: value,
                                                                                     shortForm: true)))
        }
            



        
        total += value
        
        setStackDataCategories()
    }
    
    mutating func setAsWeeklyAverage(divisorDays: Double) {
        
        totalName = "Weekly Average"
        total = total / divisorDays
        totalsBySubcategory = totalsBySubcategory.map( {DataPoint(subCategory: $0.subCategory,
                                                                  value: $0.value / divisorDays,
                                                                  formattedValue: formattedPropertyValue(propertyName,
                                                                                                         value: $0.value / divisorDays,
                                                                                                         shortForm: false)) } )

        
    }
    
    
    // return list of valid indexes for the array of data points
    func dataPointIndices() -> [Int] {
        return Array(dataPoints.indices)
    }
    
    // return category for the datapoint at the index
    func category(index: Int) -> String {
        if index < dataPoints.count {
            return dataPoints[index].category ?? "Error"
        }
        return "Error"
    }
    
    // return value for the datapoint at the index
    func value(index: Int) -> Double {
        if index < dataPoints.count {
            return dataPoints[index].value
        }
        return 0
    }
    
    /// Get category colour from index
    func categoryColor(index: Int) -> Color {
        if index < dataPoints.count {
            let cat = dataPoints[index].subCategory
            if let stackDataCat = subCategories.first(where: {$0.id == cat}) {
                return stackDataCat.color
            }
        }
        return Color.red
    }
    
    /// Get category colour from subCategory
    func categoryColor(subCategory: Int?) -> Color {
        
        if let stackDataCat = subCategories.first(where: {$0.id == subCategory}) {
            return stackDataCat.color
        }
        return Color.red
    }
    
    /// Get category label from subCategory
    func subCategoryLabel(subCategory: Int?) -> String {
        
        if let subCategory = subCategories.first(where: {$0.id == subCategory}) {
            return subCategory.label
        }
        return ""
    }
    
    func allCategoryLabels() -> [String] {
        return subCategories.map( {$0.label})
    }

    func allCategoryColors() -> [Color] {
        return subCategories.map( {$0.color})
    }
    
    func formattedTotalForCategory(category: String) -> String {
        return totalsByCategory.first(where: {$0.category == category})?.formattedValue ?? "0"
    }
    
}



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

                        tempBuckets.append(elements[index])
                    }
                    else {
                        tempBuckets.append(StatisticsBucket(startDate: bucketDate,
                                                            bucketType: bucketType))
                    }
                }
                
            }
        }
        
        elements = tempBuckets

        _ = write()
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
                                                        bucketType: bucketType))

                }
                
            }
        }
        
        logger.info("Empty buckets \(self.tempBuckets)")

    }
    
    
    /// Add activity to elements
    func addActivity(_ activityRecord: ActivityRecord) {

        print("Activity workoutTypeId : \(activityRecord.workoutTypeId)")
        for (index, bucket) in elements.enumerated() {
            let activityDate = stringToDate(dateString: dateAsString(date: activityRecord.startDateLocal))
            let bucketStartDate = stringToDate(dateString: bucket.startDateString)
            let bucketEndDate = stringToDate(dateString: bucket.endDateString)
            
            if (activityDate >= bucketStartDate) && (activityDate < bucketEndDate) {
                elements[index].activities += 1
//                elements[index].addActivityByType(activityType: activityRecord.workoutTypeId)
                elements[index].distanceMeters += activityRecord.distanceMeters
//                elements[index].addDistanceByType(activityType: activityRecord.workoutTypeId,
//                                                  distanceMeters: activityRecord.distanceMeters)
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
    
    
    func addActivityToTemp(_ activityRecord: ActivityRecord) {
 
        print("Temp Activity workoutTypeId : \(activityRecord.workoutTypeId)")

        for (index, bucket) in tempBuckets.enumerated() {
            let activityDate = stringToDate(dateString: dateAsString(date: activityRecord.startDateLocal))
            let bucketStartDate = stringToDate(dateString: bucket.startDateString)
            let bucketEndDate = stringToDate(dateString: bucket.endDateString)
            
            if (activityDate >= bucketStartDate) && (activityDate < bucketEndDate) {
                tempBuckets[index].activities += 1
//                tempBuckets[index].addActivityByType(activityType: activityRecord.workoutTypeId)
                tempBuckets[index].distanceMeters += activityRecord.distanceMeters
//                tempBuckets[index].addDistanceByType(activityType: activityRecord.workoutTypeId,
//                                                     distanceMeters: activityRecord.distanceMeters)
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
    
    
    func write() -> Bool  {
        
        guard let cacheURL = CacheURL(fileName: cacheFile) else { return false}
        
        logger.log("Writing statistics cache to JSON file")

        do {
            let data = try JSONEncoder().encode(self)

            do {
                try data.write(to: cacheURL)

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
//        return dateAsString(date: weekStart)
        
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
        
        print("Type : \(String(describing: PropertyViewParamaters[propertyName]?.stackedBarType))")
        print("byZonePropertyName \(byZonePropertyName)")
        
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
       
        print("stackedBarChartData : property : \(propertyName) : \(stackedBarChartData)")
       return stackedBarChartData
    }
    
    
    // - DELETE THIS FUNCTION
    func asStackedBarData(propertyName: String, indexNames: [String]) -> [StackedBarChartDataPoint] {
 
        var stackedBarData: [StackedBarChartDataPoint] = []
        var typeLabels: [String] = []
        if ["TSSByZone", "timeByZone"].contains(propertyName) {
            typeLabels = ["Low Aerobic", "High Aerobic", "Anaerobic"]
        } else {
            typeLabels = ["Cycling"]
        }
        
        for (i, indexName) in indexNames.enumerated() {
            if i < elements.count {
                if let value = elements[i].asCKRecord()[propertyName] as? Double {
                    stackedBarData.append(StackedBarChartDataPoint(stackIndex: indexName, stackCategory: "Value", value: value, stackCategoryColor: .blue))
                } else if let array = elements[i].asCKRecord()[propertyName] as? [Double] {
                    for (labelIndex, typeLabel) in typeLabels.enumerated() {
                        if labelIndex < array.count {
                            stackedBarData.append(StackedBarChartDataPoint(stackIndex: indexName, stackCategory: typeLabel, value: array[labelIndex], stackCategoryColor: [.blue, .green, .orange][labelIndex]))

                        }

                    }
//                    stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "Low Aerobic", value: array[0]))
//                    stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "High Aerobic", value: array[1]))
//                    stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "Anaerobic", value: array[2]))
                
               }
                
            } else {
                stackedBarData.append(StackedBarChartDataPoint(stackIndex: indexName, stackCategory: "Value", value: 0, stackCategoryColor: .blue))
           }
       }
       
       return stackedBarData
    }
    
    
    
    func asDayOfWeekStackedBarChartData(propertyName: String) -> StackedBarChartData {
        
        print("***** asDayOfWeekStackedBarChartData : \(asStackedBarChartData(propertyName: propertyName, indexNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]))")
        
        return asStackedBarChartData(propertyName: propertyName, indexNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
        
    }
    
    func asWeekStackedBarChartData(propertyName: String, filterList: [String] = []) -> StackedBarChartData {
        
        var fullList = asStackedBarChartData(propertyName: propertyName,
                                             indexNames: ["-11", "-10", "-9", "-8", "-7", "-6", "-5", "-4", "-3", "-2", "last", "this"])
        // FIX! - this needs reimplementing!
//        if filterList.count > 0 {
//            fullList = full
//            return fullList.filter( {filterList.contains($0.stackIndex)} )
//        }
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
    
    // -- DELETE EVERYTHING BELOW
    func asDayOfWeekStackedBarData(propertyName: String) -> [StackedBarChartDataPoint] {
        
        return asStackedBarData(propertyName: propertyName, indexNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
        
    }
    
    func asWeekStackedBarData(propertyName: String, filterList: [String] = []) -> [StackedBarChartDataPoint] {
        
        let fullList = asStackedBarData(propertyName: propertyName,
                                        indexNames: ["-11", "-10", "-9", "-8", "-7", "-6", "-5", "-4", "-3", "-2", "last", "this"])
        if filterList.count > 0 {
            return fullList.filter( {filterList.contains($0.stackIndex)} )
        }
        return fullList
        
    }

    func asQuarterStackedBarData(propertyName: String) -> [StackedBarChartDataPoint] {
        
        return asStackedBarData(propertyName: propertyName, indexNames: ["-3", "-2", "-1", "this"])
        
    }
    
}

