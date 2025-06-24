//
//  StatisticsBucketConfiguration.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 22/06/2025.
//

import Foundation


/// types of statistic buckets
enum BucketType: Int, CaseIterable {
    case day = 0
    case week = 1
    case quarter = 2
    case year = 3
    
}


/// Number of buckets held for each type
let StatisticsBucketCount: [BucketType: Int] = [BucketType.day: 14,
                                                BucketType.week: 12,
                                                BucketType.quarter: 4,
                                                BucketType.year: 2]


struct BucketDuration {
    var count: Int
    var unit: Calendar.Component
}

/// Length of each bucket in appropriate date units
let StatisticsBucketDuration: [BucketType: BucketDuration] = [BucketType.day: BucketDuration(count: 1, unit: .day),
                                                              BucketType.week: BucketDuration(count: 7, unit: .day),
                                                              BucketType.quarter: BucketDuration(count: 3, unit: .month),
                                                              BucketType.year: BucketDuration(count: 1, unit: .year)]


/// Configure value formatter for each property name
private let PropertyValueFormatter: [String: (Double) -> String] = ["TSS": TSSFormatter,
                                                            "TSSByZone": TSSFormatter,
                                                            "time": {val in elapsedTimeFormatter(elapsedSeconds: val, minimizeLength: true)},
                                                            "timeByZone": {val in elapsedTimeFormatter(elapsedSeconds: val, minimizeLength: false, showSeconds: true)},
                                                            "activities": {val in String(format: "%.0f", val)},
                                                            "distanceMeters": {val in distanceFormatter(distance: val, forceMeters: false)}]

/// Configure abbreviated value formatter for each property name
private let ShortFormPropertyValueFormatter: [String: (Double) -> String] = ["TSS": {val in String(format: "%.0f", val)},
                                                                             "TSSByZone": {val in String(format: "%.0f", val)},
                                                                             "time": {val in elapsedTimeFormatter(elapsedSeconds: val, minimizeLength: true, showSeconds: false)},
                                                                             "timeByZone": {val in elapsedTimeFormatter(elapsedSeconds: val, minimizeLength: true, showSeconds: false)},
                                                                             "distanceMeters": {val in distanceFormatter(distance: val, forceMeters: false, justKilometers: true)}]


func propertyValueFormatter(_ propertyName: String, shortForm: Bool = false) -> (Double) -> String {

    var formatter = PropertyValueFormatter[propertyName] ?? {val in String(format: "%.0f", val)}
    if shortForm {
        formatter = ShortFormPropertyValueFormatter[propertyName] ?? formatter
    }
    return formatter
    
}
