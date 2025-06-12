//
//  TypeStatisticsManager.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 12/06/2025.
//

import Foundation

struct ValueArray {
    var elements: [Double]
    
    func asStackedBarData( indexNames: [String]) -> [StackedBarChartDataPoint] {
        
         var stackedBarData: [StackedBarChartDataPoint] = []
        
        for (i, indexName) in indexNames.enumerated() {
            if i < elements.count {
                stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "Value", value: elements[i]))

            } else {
                stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "Value", value: 0))

            }
        }
        
        return stackedBarData
    }
}

class TypeStatistics: ObservableObject {
    
    var valueFormatter: (Double) -> String
    
    
    var weekTotal: [Double] = [0,           // This Week
                               0]           // Last Week
    var weekByDay: [ValueArray] = [ValueArray(elements: []),
                                   ValueArray(elements: [])]
    
    var weeks: ValueArray = ValueArray(elements: [])                           // 12 weeks by week
    var quarters: ValueArray = ValueArray(elements: [])                        // all data in 3-month blocks

    
    
    
    init(valueFormatter: @escaping (Double) -> String = {val in String(format: "%.0f", val)}) {
        
        self.valueFormatter = valueFormatter
        
        weekTotal[WeekId.thisWeek.rawValue] = 2
        weekTotal[WeekId.lastWeek.rawValue] = 6


        weekByDay[WeekId.thisWeek.rawValue].elements = [0, 1, 1]
        weekByDay[WeekId.lastWeek.rawValue].elements = [1, 1, 2, 1, 1, 0, 1]

        weeks.elements = [6, 7, 7, 8, 6, 7, 6, 7, 7, 6, 8, 9, 6]
        quarters.elements = [75, 70, 82, 64]
    }
    
    
    func formattedWeekTotal(_ weekId: WeekId) -> String {
        return valueFormatter(weekTotal[weekId.rawValue])
    }

    
    func weekByDayAsStackedBarData(_ weekId: WeekId) -> [StackedBarChartDataPoint] {
        return weekByDay[weekId.rawValue].asStackedBarData(indexNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
    }
    
    func weeksAsStackedBarData() -> [StackedBarChartDataPoint] {
        return weeks.asStackedBarData(indexNames: ["-11", "-10", "-9", "-8", "-7", "-6", "-5", "-4", "-3", "-2", "last", "this"])
    }
    
    func quartersAsStackedBarData() -> [StackedBarChartDataPoint] {
        return quarters.asStackedBarData(indexNames: ["23Q1", "23Q2", "23Q3", "23Q4", "24Q1", "24Q2", "24Q3", "24Q4", "25Q1", "25Q2"])
    }

}
