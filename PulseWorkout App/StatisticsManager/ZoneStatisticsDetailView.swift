//
//  ZoneStatisticsView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 07/06/2025.
//

import SwiftUI

struct ZoneStatisticsDetailView: View {
    
    @ObservedObject var statistics: ZoneStatistics
    var totalLabel: String
    var navigationTitle: String
    var foregroundColor: Color
    
    var body: some View {
        
        ScrollView {
            VStack
            {

                ZoneStatisticWeekView(statistics: statistics,
                                      totalLabel: totalLabel,
                                      weekId: WeekId.thisWeek,
                                      foregroundColor: foregroundColor)

                ZoneStatisticWeekView(statistics: statistics,
                                      totalLabel: totalLabel,
                                      weekId: WeekId.lastWeek,
                                      foregroundColor: foregroundColor)

                GroupBox(label: Text("Last 12 Weeks")
                    .foregroundColor(foregroundColor)
                    .fontWeight(.bold))
                {
                    StackedBarView(stackedBarData: statistics.weeksByZoneAsStackedBarData())
                }
                
                GroupBox(label: Text("By Quarters")
                    .foregroundColor(foregroundColor)
                    .fontWeight(.bold))
                {
                    StackedBarView(stackedBarData: statistics.quartersByZoneAsStackedBarData())
                }
                
            }

        }
        
        .navigationTitle(navigationTitle)
    }
}

#Preview {
    ZoneStatisticsDetailView(statistics: ZoneStatistics(),
                       totalLabel: "Total Load",
                       navigationTitle: "Training Load",
                       foregroundColor: TSSColor)
}

struct ZoneStatisticWeekView: View {
    
    var statistics: ZoneStatistics
    var totalLabel: String
    var weekId: WeekId
    var foregroundColor: Color
    
    var body: some View {
        GroupBox(label: Text(weekNames[weekId]!)
            .foregroundColor(foregroundColor)
            .fontWeight(.bold))
        {
            StackedBarAndDonutView(stackedBarData: statistics.weekByDayAsStackedBarData(weekId),
                                   donutChartData: statistics.weekByZoneAsDonutChartData(weekId),
                                   donutChartTotalName: totalLabel,
                                   donutChartTotalValue: statistics.formattedWeekTotal(weekId))
        }
    }
}
