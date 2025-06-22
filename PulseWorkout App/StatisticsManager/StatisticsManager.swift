//
//  StatisticsManager.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 08/06/2025.
//

import Foundation
import os
import CloudKit
import SwiftUI




enum BucketType: Int, CaseIterable {
    case day = 0
    case week = 1
    case quarter = 2
    case year = 3
    
}

let StatisticsBucketCount: [BucketType: Int] = [BucketType.day: 14,
                                                BucketType.week: 12,
                                                BucketType.quarter: 4,
                                                BucketType.year: 2]
struct BucketDuration {
    var count: Int
    var unit: Calendar.Component
}

let StatisticsBucketDuration: [BucketType: BucketDuration] = [BucketType.day: BucketDuration(count: 1, unit: .day),
                                                              BucketType.week: BucketDuration(count: 7, unit: .day),
                                                              BucketType.quarter: BucketDuration(count: 3, unit: .month),
                                                              BucketType.year: BucketDuration(count: 1, unit: .year)]

let PropertyValueFormatter: [String: (Double) -> String] = ["TSS": TSSFormatter,
                                                            "TSSByZone": TSSFormatter,
                                                            "time": {val in elapsedTimeFormatter(elapsedSeconds: val, minimizeLength: true)},
                                                            "timeByZone": {val in elapsedTimeFormatter(elapsedSeconds: val, minimizeLength: true)},
                                                            "activities": {val in String(format: "%.0f", val)},
                                                            "distanceMeters": {val in distanceFormatter(distance: val, forceMeters: false)}]


struct ViewParameters {
    var imageSystemName: String
    var titleText: String
    var foregroundColor: Color
    var totalLabel: String
    var byZonePropertyName: String?
    var navigationTitle: String
}

let PropertyViewParamaters: [String: ViewParameters] = [
    "activities": ViewParameters(imageSystemName: "figure.run", titleText: "Activities",
                                 foregroundColor: activitiesColor, totalLabel: "Total Activities", navigationTitle: "Activities"),
    "TSS": ViewParameters(imageSystemName: "figure.strengthtraining.traditional.circle", titleText: "Training Load",
                          foregroundColor: TSSColor, totalLabel: "Total Load", byZonePropertyName: "TSSByZone", navigationTitle: "Training Load"),
    "distanceMeters": ViewParameters(imageSystemName: distanceIcon, titleText: "Distance",
                                     foregroundColor: distanceColor, totalLabel: "Total Distance", navigationTitle: "Distance"),
    "time": ViewParameters(imageSystemName: "stopwatch", titleText: "Activity Time - by Heart Rate Zone",
                           foregroundColor: timeByHRColor, totalLabel: "Total Time", byZonePropertyName: "timeByZone", navigationTitle: "Activity Time by HR Zone")
]





struct StatisticsBucket: Codable {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var startDateString: String
    var endDateString: String
    var bucketType: Int
    var activities: Double
    var distanceMeters: Double
    var time: Double
    var TSS: Double
    var TSSByZone: [Double]
    var timeByZone: [Double]
    
    init(startDate: Date, bucketType: BucketType) {
        
        self.id = UUID()
        self.startDate = startDate
        self.endDate = Calendar.current.date(byAdding: StatisticsBucketDuration[bucketType]!.unit,
                                             value: StatisticsBucketDuration[bucketType]!.count,
                                             to: startDate)!
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        dateFormatter.timeZone = .current
        self.startDateString = startDate.formatted(.iso8601
            .year()
            .month()
            .day())
        self.endDateString = endDate.formatted(.iso8601
            .year()
            .month()
            .day())
        self.bucketType = bucketType.rawValue
        self.activities = 0
        self.distanceMeters = 0
        self.time = 0
        self.TSS = 0
        self.TSSByZone = [0, 0, 0]
        self.timeByZone = [0, 0, 0]
    }
    
    
    // Create a statistics bucket as 7-day average from array of buckets - which must be of the same type
    init(bucketArray: [StatisticsBucket]) {
        
        let hasAllSameType = bucketArray.allSatisfy({ $0.bucketType == bucketArray.first?.bucketType })
        
        if let first = bucketArray.first {
            let hasAllSameType = bucketArray.allSatisfy({ $0.bucketType == first.bucketType })
            let bucketsStartDate = first.startDate
            
            self.id = UUID()
            self.startDate = first.startDate
            self.endDate = bucketArray.last!.endDate
            
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            dateFormatter.timeZone = .current
            self.startDateString = startDate.formatted(.iso8601
                .year()
                .month()
                .day())
            self.endDateString = endDate.formatted(.iso8601
                .year()
                .month()
                .day())
            self.bucketType = first.bucketType
            
            let days: Int = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 1  // FIX TO DATE STRINGS!
            let divisor: Double = Double(days) / 7
            self.activities = bucketArray.reduce(0) { result, bucket
                in
                result + (bucket.activities / divisor)}
            self.distanceMeters = bucketArray.reduce(0) { result, bucket
                in
                result + (bucket.distanceMeters / divisor)}
            self.time = bucketArray.reduce(0) { result, bucket
                in
                result + (bucket.time / divisor)}
            self.TSS = bucketArray.reduce(0) { result, bucket
                in
                result + (bucket.TSS / divisor)}
            self.TSSByZone = bucketArray.reduce([0, 0, 0]) { result, bucket
                in
                [result[0] + (bucket.TSSByZone[0] / divisor),
                 result[1] + (bucket.TSSByZone[1] / divisor),
                 result[2] + (bucket.TSSByZone[2] / divisor),
                ]
            }

            self.timeByZone = bucketArray.reduce([0, 0, 0]) { result, bucket
                in
                [result[0] + (bucket.timeByZone[0] / divisor),
                 result[1] + (bucket.timeByZone[1] / divisor),
                 result[2] + (bucket.timeByZone[2] / divisor),
                ]
            }
            
        }
        else {
            self.id = UUID()
            self.startDate = Date.now
            self.endDate = Date.now
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            dateFormatter.timeZone = .current
            self.startDateString = startDate.formatted(.iso8601
                .year()
                .month()
                .day())
            self.endDateString = endDate.formatted(.iso8601
                .year()
                .month()
                .day())
            self.bucketType = 0
            self.activities = 0
            self.distanceMeters = 0
            self.time = 0
            self.TSS = 0
            self.TSSByZone = [0, 0, 0]
            self.timeByZone = [0, 0, 0]
        }

    
    }
    
    func asCKRecord() -> CKRecord {
// !!        recordID = CKRecord.ID()
        let ckRecord = CKRecord(recordType: "StatisticBucket", recordID: CloudKitOperation().getCKRecordID())
        ckRecord["startDate"] = startDate as CKRecordValue
        ckRecord["endDate"] = endDate as CKRecordValue
        ckRecord["startDateString"] = startDateString as CKRecordValue
        ckRecord["endDateString"] = endDateString as CKRecordValue
        ckRecord["bucketType"] = bucketType as CKRecordValue
        ckRecord["activities"] = activities as CKRecordValue
        ckRecord["distanceMeters"] = distanceMeters as CKRecordValue
        ckRecord["time"] = time as CKRecordValue
        ckRecord["TSS"] = TSS as CKRecordValue
        ckRecord["TSSByZone"] = TSSByZone as CKRecordValue
        ckRecord["timeByZone"] = timeByZone as CKRecordValue

        return ckRecord

    }
    

    
    
    func TSSArrayAsDonutChartData() -> [DonutChartDataPoint] {
        return arrayAsDonutChartData(array: TSSByZone, labels: ["Low Aerobic", "High Aerobic", "Anaerobic"], valueFormatter: TSSFormatter)
    }
    
    
    func asDonutChartData(propertyName: String, labels: [String] ) -> [DonutChartDataPoint] {
        
        let formatter = PropertyValueFormatter[propertyName] ?? {val in String(format: "%.0f", val)}
        
        if let array = asCKRecord()[propertyName] as? [Double] {
            
            return arrayAsDonutChartData(array: array,
                                         labels: labels,
                                         valueFormatter: formatter)
        }
        return arrayAsDonutChartData(array: [],
                                     labels: labels,
                                     valueFormatter: formatter)
    }
    
    
    func asZoneDonutChartData(propertyName: String) -> [DonutChartDataPoint] {
        
        return asDonutChartData(propertyName: propertyName, labels: ["Low Aerobic", "High Aerobic", "Anaerobic"])
        
    }
    
    
    func formattedValue(propertyName: String) -> String {
 
        let formatter = PropertyValueFormatter[propertyName] ?? {val in String(format: "%.0f", val)}
        
        if let value = asCKRecord()[propertyName] as? Double {
            return formatter(value)
        }
        
        return "Error"
    }
}



private func arrayAsDonutChartData(array: [Double], labels: [String], valueFormatter: @escaping (Double) -> String) -> [DonutChartDataPoint] {
    
    var chartData: [DonutChartDataPoint] = []
   
    for (i, label) in labels.enumerated() {
        if i < array.count {
            chartData.append(DonutChartDataPoint(name: label,
                                                 value: array[i],
                                                 formattedValue: valueFormatter(array[i])))
        } else {
            chartData.append(DonutChartDataPoint(name: label,
                                                 value: 0,
                                                 formattedValue: valueFormatter(0)))
        }
    }
   
    return chartData
}


class StatsBuckets: NSObject, Codable {
    
    let cacheFile = "statisticsCache.json"
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "statsBuckets")
    
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
        
        var todayComponents = Calendar.current.dateComponents([.day, .year, .month], from: Date.now)
        todayComponents.timeZone = .gmt
        let today = Calendar.current.date(from: todayComponents)!
        print("now \(Date.now)")
        print("today \(today)")
        print("components \(todayComponents)")
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MM yyyy HH:mm:ss"
        
        print("today 2...")
        print(formatter.string(from: today))
        
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

        
        let bucketStartDate: [BucketType: Date] = [.day: today,
                                                   .week: weekStart,
                                                   .quarter: quarterStart,
                                                   .year: yearStart]
        
        for bucketType in BucketType.allCases {
            
            for count in 0..<StatisticsBucketCount[bucketType]! {
                
                // need buckettypestartdate istead of just today
                if let bucketDate = Calendar.current.date(byAdding: StatisticsBucketDuration[bucketType]!.unit,
                                                          value: -1 * count * StatisticsBucketDuration[bucketType]!.count,
                                                          to: bucketStartDate[bucketType]!) {
                    print("bucketDate:")
                    print(formatter.string(from: bucketDate))
                    if let index = elements.firstIndex(where: {(formatter.string(from: $0.startDate) == formatter.string(from: bucketDate)) &&
                        ( $0.bucketType == bucketType.rawValue)} ) {
                        print("Found at index: \(index)")
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
        print(elements)
        _ = write()
    }
    
    
    /// Create a set of empty buckets
    func emptyTempBuckets() {
        
        tempBuckets = []
        
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
        
        let bucketStartDate: [BucketType: Date] = [.day: today,
                                                   .week: weekStart,
                                                   .quarter: quarterStart,
                                                   .year: yearStart]
        
        for bucketType in BucketType.allCases {
            
            for count in 0..<StatisticsBucketCount[bucketType]! {
                
                if let bucketDate = Calendar.current.date(byAdding: StatisticsBucketDuration[bucketType]!.unit,
                                                          value: -1 * count * StatisticsBucketDuration[bucketType]!.count,
                                                          to: bucketStartDate[bucketType]!) {
 
                    tempBuckets.append(StatisticsBucket(startDate: bucketDate,
                                                    bucketType: bucketType))

                }
                
            }
        }
        
        logger.info("Empty buckets \(self.tempBuckets)")

    }
    
    
    /// Add activity to elements
    func addActivity(_ activityRecord: ActivityRecord) {

        // FIX - USE TS IF NO HR AND VICE VERSA!!
        
        for (index, bucket) in elements.enumerated() {
            let activityDate = stringToDate(dateString: dateAsString(date: activityRecord.startDateLocal))
            let bucketStartDate = stringToDate(dateString: bucket.startDateString)
            let bucketEndDate = stringToDate(dateString: bucket.endDateString)
            
            if (activityDate >= bucketStartDate) && (activityDate < bucketEndDate) {
                elements[index].activities += 1
                elements[index].distanceMeters += activityRecord.distanceMeters
                elements[index].time += activityRecord.movingTime
                elements[index].TSS +=  (activityRecord.TSS ?? 0)
                if activityRecord.TSSbyPowerZone.count == 6 {
                    elements[index].TSSByZone = [activityRecord.TSSbyPowerZone[0] + activityRecord.TSSbyPowerZone[1],
                                                 activityRecord.TSSbyPowerZone[2] + activityRecord.TSSbyPowerZone[3],
                                                 activityRecord.TSSbyPowerZone[4] + activityRecord.TSSbyPowerZone[5]]
                } else {
                    elements[index].TSSByZone = [0, 0, 0]
                }

                if activityRecord.movingTimebyHRZone.count == 5 {
                    elements[index].timeByZone = [activityRecord.movingTimebyHRZone[0] + activityRecord.movingTimebyHRZone[1],
                                                  activityRecord.movingTimebyHRZone[2] + activityRecord.movingTimebyHRZone[3],
                                                  activityRecord.movingTimebyHRZone[4]]
                }
                else {
                    elements[index].timeByZone = [0, 0, 0]
                }

                
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
                tempBuckets[index].time += activityRecord.movingTime
                tempBuckets[index].TSS += (activityRecord.TSS ?? 0)
                
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
            let JSONData = try decoder.decode(StatsBuckets.self, from: data)
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

    
    func getBucketsByType(bucketType: BucketType) -> StatsBuckets {
        
        let buckets = elements.filter({ $0.bucketType == bucketType.rawValue })
            .sorted { itemA, itemB in
                itemA.startDate < itemB.startDate
            }

        return StatsBuckets(elements: buckets)
    }
    
    
    func yearBuckets() -> StatsBuckets {
        return getBucketsByType(bucketType: .year)
    }
    
    
    func quarterBuckets() -> StatsBuckets {
        return getBucketsByType(bucketType: .quarter)
    }
    
    
    func weekBuckets() -> StatsBuckets {
        return getBucketsByType(bucketType: .week)
    }

    
    func thisWeekDayBuckets() -> StatsBuckets {
        
        let buckets = getBucketsByType(bucketType: .day).elements
            .filter( {stringToDate(dateString: $0.startDateString) >= thisWeekStartDate()})
        
        logger.info("thisWeekDayBuckets \(buckets)")
        return StatsBuckets(elements: buckets)
    }

    
    func lastWeekDayBuckets() -> StatsBuckets {
        
        let buckets = getBucketsByType(bucketType: .day).elements
            .filter( {stringToDate(dateString: $0.startDateString) >= lastWeekStartDate()})
            .filter( {stringToDate(dateString: $0.startDateString) < thisWeekStartDate()})
        
        return StatsBuckets(elements: buckets)
    }
    
    func activitiesAsStackedBarData(indexNames: [String]) -> [StackedBarChartDataPoint] {
        
        var stackedBarData: [StackedBarChartDataPoint] = []
       
        for (i, indexName) in indexNames.enumerated() {
            if i < elements.count {
                stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "Value", value: elements[i].activities))
            } else {
                stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "Value", value: 0))
           }
       }
       
       return stackedBarData

    }

    
    func asStackedBarData(propertyName: String, indexNames: [String]) -> [StackedBarChartDataPoint] {
 
        var stackedBarData: [StackedBarChartDataPoint] = []
       
        for (i, indexName) in indexNames.enumerated() {
            if i < elements.count {
                if let value = elements[i].asCKRecord()[propertyName] as? Double {
                    stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "Value", value: value))
                } else if let array = elements[i].asCKRecord()[propertyName] as? [Double] {
                    stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "Low Aerobic", value: array[0]))
                    stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "High Aerobic", value: array[1]))
                    stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "Anaerobic", value: array[2]))
                
               }
                
            } else {
                stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "Value", value: 0))
           }
       }
       
       return stackedBarData
    }
    
    
    func asDayOfWeekStackedBarData(propertyName: String) -> [StackedBarChartDataPoint] {
        
        return asStackedBarData(propertyName: propertyName, indexNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
        
    }
    
    func asWeekStackedBarData(propertyName: String) -> [StackedBarChartDataPoint] {
        
        return asStackedBarData(propertyName: propertyName, indexNames: ["-11", "-10", "-9", "-8", "-7", "-6", "-5", "-4", "-3", "-2", "last", "this"])
        
    }

    func asQuarterStackedBarData(propertyName: String) -> [StackedBarChartDataPoint] {
        
        return asStackedBarData(propertyName: propertyName, indexNames: ["-3", "-2", "-1", "this"])
        
    }
    
}



class StatisticsManager: ObservableObject {
    
    ///Access StatisticsManager through StatisticsManager.shared
    public static let shared = StatisticsManager()

    
    @Published var thisWeekDayBuckets: StatsBuckets
    @Published var lastWeekDayBuckets: StatsBuckets

    @Published var weekBuckets: StatsBuckets
    @Published var quarterBuckets: StatsBuckets

    @Published var yearBuckets: StatsBuckets

    

    var statsBuckets: StatsBuckets

    init() {
        self.statsBuckets = StatsBuckets()
        self.thisWeekDayBuckets = statsBuckets.thisWeekDayBuckets()
        self.lastWeekDayBuckets = statsBuckets.lastWeekDayBuckets()
        self.weekBuckets = statsBuckets.weekBuckets()
        self.quarterBuckets = statsBuckets.quarterBuckets()
        self.yearBuckets = statsBuckets.yearBuckets()
        
        print("quarterbuckets: \(quarterBuckets.elements)")

    }
    
    func reset() {
        DispatchQueue.main.async {
            self.thisWeekDayBuckets = self.statsBuckets.thisWeekDayBuckets()
            self.lastWeekDayBuckets = self.statsBuckets.lastWeekDayBuckets()
            self.weekBuckets = self.statsBuckets.weekBuckets()
            self.quarterBuckets = self.statsBuckets.quarterBuckets()
            self.yearBuckets = self.statsBuckets.yearBuckets()

        }
    }
    
    
    func thisWeek() -> StatisticsBucket {
        return weekBuckets.elements.last!
    }

    
    func lastWeek() -> StatisticsBucket {
        let weekCount = weekBuckets.elements.count
        let lastWeekIndex = max(weekCount - 2, 0)
        return weekBuckets.elements[lastWeekIndex]
    }
    
    func thisYear() -> StatisticsBucket {
        return yearBuckets.elements.last!
    }

    func lastYear() -> StatisticsBucket {
        return yearBuckets.elements.first!
    }
    
    func buildStatistics() {
        statsBuckets.emptyTempBuckets()
        
        CKActivityQueryOperation(startDate: nil,
                                 blockCompletionFunction: addActivitiesToStats,
                                 resultsLimit: 100,
                                 qualityOfService: .userInitiated).execute()
    }
    
    func addActivitiesToStats(ckRecordList: [CKRecord]) -> Void {
        
        let activityList = ckRecordList.map( {ActivityRecord(fromCKRecord: $0)})
        _ = activityList.map( {statsBuckets.addActivityToTemp($0) })
        
        statsBuckets.copyTempToElements()
        
        _ = statsBuckets.write()
        
        reset()
        
    }
    
    
}

