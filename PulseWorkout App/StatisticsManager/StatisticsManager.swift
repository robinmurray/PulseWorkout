//
//  StatisticsManager.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 08/06/2025.
//

import Foundation

enum WeekId : Int {
    
    case thisWeek = 0           // Data index for current week
    case lastWeek = 1           // Data index for last week
}

let weekNames: [WeekId: String] = [WeekId.thisWeek: "This Week",
                                   WeekId.lastWeek: "Last Week"]


class StatisticsManager: ObservableObject {
    
    ///Access StatisticsManager through StatisticsManager.shared
    public static let shared = StatisticsManager()

    @Published var weekActivities: [Double] = [0,              // This week
                                               0]              // Last Week
    @Published var weekDistance: [Double] = [0,                // This week
                                             0]                // Last Week
    @Published var weekTime: [Double] = [0,                    // This week
                                         0]                    // Last Week
    @Published var weekTSS: [Double] = [0,                     // This week
                                        0]                     // Last Week
    
    @Published var tssStatistics: ZoneStatistics
    @Published var hrStatistics: ZoneStatistics
    @Published var activityStatistics: TypeStatistics
    @Published var distanceStatistics: TypeStatistics

    init() {
        tssStatistics = ZoneStatistics(valueFormatter: TSSFormatter)
        hrStatistics = ZoneStatistics(valueFormatter: {val in elapsedTimeFormatter(elapsedSeconds: val, minimizeLength: true)})
        activityStatistics = TypeStatistics(valueFormatter: {val in String(format: "%.0f", val)})
        distanceStatistics = TypeStatistics(valueFormatter: {val in distanceFormatter(distance: val, forceMeters: false)})
        
        weekActivities[WeekId.thisWeek.rawValue] = 2
        weekActivities[WeekId.lastWeek.rawValue] = 8
        weekDistance[WeekId.thisWeek.rawValue] = 150
        weekDistance[WeekId.lastWeek.rawValue] = 380
        weekTime[WeekId.thisWeek.rawValue] = 2000
        weekTime[WeekId.lastWeek.rawValue] = 8800
        weekTSS[WeekId.thisWeek.rawValue] = 180
        weekTSS[WeekId.lastWeek.rawValue] = 780
    }
    
    func weekActivitiesAsStackedBarData() -> [StackedBarChartDataPoint] {
        var stackedBarData: [StackedBarChartDataPoint] = []
        
        stackedBarData.append(StackedBarChartDataPoint(index: "This Week", type: "Count", value: weekActivities[0]))
        stackedBarData.append(StackedBarChartDataPoint(index: "Last Week", type: "Count", value: weekActivities[1]))
        
        return stackedBarData

    }
}

