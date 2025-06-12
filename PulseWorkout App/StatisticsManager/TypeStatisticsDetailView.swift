//
//  TypeStatisticsDetailView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 12/06/2025.
//

import SwiftUI


struct TypeStatisticsDetailView: View {
    
    @ObservedObject var statistics: TypeStatistics
    var navigationTitle: String
    var foregroundColor: Color
    
    var body: some View {
        
        ScrollView {
            VStack
            {

                TypeStatisticWeekView(statistics: statistics,
                                      weekId: WeekId.thisWeek,
                                      foregroundColor: foregroundColor)

                TypeStatisticWeekView(statistics: statistics,
                                      weekId: WeekId.lastWeek,
                                      foregroundColor: foregroundColor)

                GroupBox(label: Text("Last 12 Weeks")
                    .foregroundColor(foregroundColor)
                    .fontWeight(.bold))
                {
                    StackedBarView(stackedBarData: statistics.weeksAsStackedBarData())
                }
                
                GroupBox(label: Text("By Quarters")
                    .foregroundColor(foregroundColor)
                    .fontWeight(.bold))
                {
                    StackedBarView(stackedBarData: statistics.quartersAsStackedBarData())
                }
                
            }

        }
        
        .navigationTitle(navigationTitle)
    }
}

#Preview {
    TypeStatisticsDetailView(statistics: TypeStatistics(),
                             navigationTitle: "Activities",
                             foregroundColor: TSSColor)
}

struct TypeStatisticWeekView: View {
    
    var statistics: TypeStatistics
    var weekId: WeekId
    var foregroundColor: Color
    
    var body: some View {
        GroupBox(label: Text(weekNames[weekId]!)
            .foregroundColor(foregroundColor)
            .fontWeight(.bold))
        {
            StackedBarView(stackedBarData: statistics.weekByDayAsStackedBarData(weekId))

        }
    }
}
