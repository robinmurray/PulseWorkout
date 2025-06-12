//
//  TSSStatisticsSummaryView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 08/06/2025.
//

import SwiftUI


struct StackedBarAndDonutView: View {
    
    var stackedBarData: [StackedBarChartDataPoint]
    var donutChartData: [DonutChartDataPoint]
    var donutChartTotalName: String
    var donutChartTotalValue: String
    
    
    var body: some View {
        VStack
        {
            
            StackedBarView(stackedBarData: stackedBarData)
            DonutChartView(chartData: donutChartData,
                           totalName: donutChartTotalName,
                           totalValue: donutChartTotalValue)
            
        }
    }
}


struct ZoneStatisticsSummaryView: View {
    @ObservedObject var statistics: ZoneStatistics
    var imageSystemName: String
    var titleText: String
    var totalText: String
    var foregroundColor: Color
    var detailView: StatisticsSummaryView.NavigationTarget
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        
        GroupBox(label:
                    VStack {
            HStack {
                Image(systemName: imageSystemName)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                Text(titleText)
                Spacer()
                
                
                Button {
                    navigationCoordinator.goToView(targetView: detailView)
                } label: {
                    HStack{
                        Image(systemName: "calendar")
                        Image(systemName: "chevron.forward")
                    }
                 }

            }
            .foregroundColor(foregroundColor)

        }
        )
        {
            StackedBarAndDonutView(stackedBarData: statistics.weekByDayAsStackedBarData(WeekId.thisWeek),
                                   donutChartData: statistics.weekByZoneAsDonutChartData(WeekId.thisWeek),
                                   donutChartTotalName: totalText,
                                   donutChartTotalValue: statistics.formattedWeekTotal(WeekId.thisWeek))
        }

    }

}

#Preview {
    let navigationCoordinator = NavigationCoordinator()
    
    ZoneStatisticsSummaryView(statistics: ZoneStatistics(),
                              imageSystemName: "figure.strengthtraining.traditional.circle",
                              titleText: "Training Load",
                              totalText: "Total Load",
                              foregroundColor: TSSColor,
                              detailView: StatisticsSummaryView.NavigationTarget.TSSStatisticsView,
                              navigationCoordinator: navigationCoordinator)
}


