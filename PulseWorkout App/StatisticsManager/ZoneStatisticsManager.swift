//
//  TSSStatisticsManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 07/06/2025.
//

import Foundation




struct ValueByZone {
    var anaerobic: Double
    var hiAerobic: Double
    var loAerobic: Double
    
    func asDonutChartData(valueFormatter: @escaping (Double) -> String) -> [DonutChartDataPoint] {
        
        return [DonutChartDataPoint(name: "Low Aerobic",
                                    value: loAerobic,
                                    formattedValue: valueFormatter(loAerobic)),
                DonutChartDataPoint(name: "High Aerobic",
                                    value: hiAerobic,
                                    formattedValue: valueFormatter(hiAerobic)),
                DonutChartDataPoint(name: "Anaerobic",
                                    value: anaerobic,
                                    formattedValue: valueFormatter(anaerobic))]


    }
}

struct ValueByZoneArray {
    var elements: [ValueByZone]
    
    func asStackedBarData( indexNames: [String]) -> [StackedBarChartDataPoint] {
        
         var stackedBarData: [StackedBarChartDataPoint] = []
        
        for (i, indexName) in indexNames.enumerated() {
            if i < elements.count {
                stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "Low Aerobic", value: elements[i].loAerobic))
                stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "High Aerobic", value: elements[i].hiAerobic))
                stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "Anaerobic", value: elements[i].anaerobic))

            } else {
                stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "Low Aerobic", value: 0))
                stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "High Aerobic", value: 0))
                stackedBarData.append(StackedBarChartDataPoint(index: indexName, type: "Anaerobic", value: 0))

            }
        }
        
        return stackedBarData
    }
}


class ZoneStatistics: ObservableObject {

    var valueFormatter: (Double) -> String
    
    
    var weekTotal: [Double] = [0,           // This Week
                               0]           // Last Week
    var weekByZone: [ValueByZone] = [ValueByZone(anaerobic: 0, hiAerobic: 0, loAerobic: 0),     // This Week
                                     ValueByZone(anaerobic: 0, hiAerobic: 0, loAerobic: 0)]     // Last Week
    var weekByDay: [ValueByZoneArray] = [ValueByZoneArray(elements:[]),                         // This Week
                                         ValueByZoneArray(elements: [])]                        // Last Week
    
    var weeksByZone: ValueByZoneArray = ValueByZoneArray(elements:[])                           // 12 weeks by week
    var quartersByZone: ValueByZoneArray = ValueByZoneArray(elements:[])                        // all data in 3-month blocks

    
    
    
    init(valueFormatter: @escaping (Double) -> String = {val in String(format: "%.1f", val)}) {
        
        self.valueFormatter = valueFormatter
        
        weekTotal[WeekId.thisWeek.rawValue] = 750
        weekTotal[WeekId.lastWeek.rawValue] = 670


        weekByZone[WeekId.thisWeek.rawValue] = ValueByZone(anaerobic: 150, hiAerobic: 400, loAerobic: 200)
        weekByZone[WeekId.lastWeek.rawValue] = ValueByZone(anaerobic: 120, hiAerobic: 380, loAerobic: 170)
        
        weekByDay[WeekId.thisWeek.rawValue] = ValueByZoneArray(elements:[ValueByZone(anaerobic: 50, hiAerobic: 200, loAerobic: 70),
                                                                         ValueByZone(anaerobic: 100, hiAerobic: 200, loAerobic: 130)])
        weekByDay[WeekId.lastWeek.rawValue] = ValueByZoneArray(elements:[ValueByZone(anaerobic: 10, hiAerobic: 30, loAerobic: 10),
                                                                         ValueByZone(anaerobic: 20, hiAerobic: 100, loAerobic: 30),
                                                                         ValueByZone(anaerobic: 15, hiAerobic: 50, loAerobic: 20),
                                                                         ValueByZone(anaerobic: 15, hiAerobic: 90, loAerobic: 40),
                                                                         ValueByZone(anaerobic: 10, hiAerobic: 20, loAerobic: 10),
                                                                         ValueByZone(anaerobic: 20, hiAerobic: 50, loAerobic: 50),
                                                                         ValueByZone(anaerobic: 30, hiAerobic: 40, loAerobic: 10)])

        weeksByZone = ValueByZoneArray(elements: [ValueByZone(anaerobic: 150, hiAerobic: 400, loAerobic: 200),
                                                ValueByZone(anaerobic: 120, hiAerobic: 380, loAerobic: 170),
                                                ValueByZone(anaerobic: 115, hiAerobic: 350, loAerobic: 220),
                                                ValueByZone(anaerobic: 215, hiAerobic: 490, loAerobic: 140),
                                                ValueByZone(anaerobic: 110, hiAerobic: 320, loAerobic: 210),
                                                ValueByZone(anaerobic: 220, hiAerobic: 450, loAerobic: 150),
                                                ValueByZone(anaerobic: 130, hiAerobic: 340, loAerobic: 210),
                                                ValueByZone(anaerobic: 230, hiAerobic: 440, loAerobic: 110),
                                                ValueByZone(anaerobic: 130, hiAerobic: 340, loAerobic: 210),
                                                ValueByZone(anaerobic: 230, hiAerobic: 440, loAerobic: 110),
                                                ValueByZone(anaerobic: 130, hiAerobic: 340, loAerobic: 210),
                                                ValueByZone(anaerobic: 230, hiAerobic: 440, loAerobic: 110)])
        quartersByZone = ValueByZoneArray(elements: [ValueByZone(anaerobic: 1150, hiAerobic: 1400, loAerobic: 1200),
                                                   ValueByZone(anaerobic: 1120, hiAerobic: 1380, loAerobic: 1170),
                                                   ValueByZone(anaerobic: 1115, hiAerobic: 1350, loAerobic: 1220),
                                                   ValueByZone(anaerobic: 1215, hiAerobic: 1490, loAerobic: 1140),
                                                   ValueByZone(anaerobic: 1110, hiAerobic: 1320, loAerobic: 1210),
                                                   ValueByZone(anaerobic: 1220, hiAerobic: 1450, loAerobic: 1150),
                                                   ValueByZone(anaerobic: 1130, hiAerobic: 1340, loAerobic: 1210),
                                                   ValueByZone(anaerobic: 1230, hiAerobic: 1440, loAerobic: 1110),
                                                   ValueByZone(anaerobic: 1130, hiAerobic: 1340, loAerobic: 1210),
                                                   ValueByZone(anaerobic: 1230, hiAerobic: 1440, loAerobic: 1110),
                                                   ValueByZone(anaerobic: 1130, hiAerobic: 1340, loAerobic: 1210),
                                                   ValueByZone(anaerobic: 1230, hiAerobic: 1440, loAerobic: 1110)])
    }
    
    
    func formattedWeekTotal(_ weekId: WeekId) -> String {
        return valueFormatter(weekTotal[weekId.rawValue])
    }

    
    func weekByZoneAsDonutChartData(_ weekId: WeekId) -> [DonutChartDataPoint] {
        return weekByZone[weekId.rawValue].asDonutChartData(valueFormatter: valueFormatter)
    }
    
    func weekByDayAsStackedBarData(_ weekId: WeekId) -> [StackedBarChartDataPoint] {
        return weekByDay[weekId.rawValue].asStackedBarData(indexNames: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
    }

    
    func weeksByZoneAsStackedBarData() -> [StackedBarChartDataPoint] {
        return weeksByZone.asStackedBarData(indexNames: ["-11", "-10", "-9", "-8", "-7", "-6", "-5", "-4", "-3", "-2", "last", "this"])
    }
    
    
    func quartersByZoneAsStackedBarData() -> [StackedBarChartDataPoint] {
        return quartersByZone.asStackedBarData(indexNames: ["23Q1", "23Q2", "23Q3", "23Q4", "24Q1", "24Q2", "24Q3", "24Q4", "25Q1", "25Q2"])
    }

}
