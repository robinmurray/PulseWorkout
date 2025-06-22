//
//  DetailStatisticBarDonutView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 20/06/2025.
//

import SwiftUI

struct DetailStatisticBarDonutView: View {
    
    @ObservedObject var statisticsManager: StatisticsManager = StatisticsManager.shared
    var propertyName: String
    
    
    var body: some View {
        
        VStack {
            ActivityHistoryHeaderView()
            Spacer()
 
            ScrollView {
                GroupBox(label: Text("This Week")
                    .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                    .fontWeight(.bold))
                {
                    
                    StackedBarAndDonutView(
                        stackedBarData: statisticsManager.thisWeekDayBuckets.asDayOfWeekStackedBarData(propertyName: PropertyViewParamaters[propertyName]?.byZonePropertyName ?? ""),
                        donutChartData: statisticsManager.thisWeek().asZoneDonutChartData(propertyName: PropertyViewParamaters[propertyName]?.byZonePropertyName ?? ""),
                        donutChartTotalName: PropertyViewParamaters[propertyName]?.totalLabel ?? "Total",
                        donutChartTotalValue: statisticsManager.thisWeek().formattedValue(propertyName: propertyName),
                        formatter: propertyValueFormatter(propertyName, shortForm: true))

                }
                
                GroupBox(label: Text("Last Week")
                    .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                    .fontWeight(.bold))
                {

                    StackedBarAndDonutView(
                        stackedBarData: statisticsManager.lastWeekDayBuckets.asDayOfWeekStackedBarData(propertyName: PropertyViewParamaters[propertyName]?.byZonePropertyName ?? ""),
                        donutChartData: statisticsManager.lastWeek().asZoneDonutChartData(propertyName: PropertyViewParamaters[propertyName]?.byZonePropertyName ?? ""),
                        donutChartTotalName: PropertyViewParamaters[propertyName]?.totalLabel ?? "Total",
                        donutChartTotalValue: statisticsManager.lastWeek().formattedValue(propertyName: propertyName),
                        formatter: propertyValueFormatter(propertyName, shortForm: true))

                }
                
                GroupBox(label: Text("Last 12 Weeks")
                    .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                    .fontWeight(.bold))
                {


                    StackedBarAndDonutView(
                        stackedBarData: statisticsManager.weekBuckets.asWeekStackedBarData(propertyName: PropertyViewParamaters[propertyName]?.byZonePropertyName ?? ""),
                        donutChartData: StatisticsBucket(bucketArray: statisticsManager.weekBuckets.elements) .asZoneDonutChartData(propertyName: PropertyViewParamaters[propertyName]?.byZonePropertyName ?? ""),
                        donutChartTotalName: "Weekly Average",
                        donutChartTotalValue: StatisticsBucket(bucketArray: statisticsManager.weekBuckets.elements).formattedValue(propertyName: propertyName),
                        formatter: propertyValueFormatter(propertyName, shortForm: true))
     
                    
                }
                
                GroupBox(label: Text("By Quarters")
                    .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                    .fontWeight(.bold))
                {
                    
                    StackedBarAndDonutView(
                        stackedBarData: statisticsManager.quarterBuckets.asQuarterStackedBarData(propertyName: PropertyViewParamaters[propertyName]?.byZonePropertyName ?? ""),
                        donutChartData: StatisticsBucket(bucketArray: statisticsManager.quarterBuckets.elements) .asZoneDonutChartData(propertyName: PropertyViewParamaters[propertyName]?.byZonePropertyName ?? ""),
                        donutChartTotalName: "Weekly Average",
                        donutChartTotalValue: StatisticsBucket(bucketArray: statisticsManager.quarterBuckets.elements).formattedValue(propertyName: propertyName),
                        formatter: propertyValueFormatter(propertyName, shortForm: true))
                    
                }
                
                GroupBox(label: Text("This Year")
                    .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                    .fontWeight(.bold))
                {
                    
                    DonutChartView(chartData: statisticsManager.thisYear().asZoneDonutChartData(propertyName: PropertyViewParamaters[propertyName]?.byZonePropertyName ?? ""),
                                   totalName: PropertyViewParamaters[propertyName]?.totalLabel ?? "Total",
                                   totalValue: statisticsManager.thisYear().formattedValue(propertyName: propertyName))

                }
                
                GroupBox(label: Text("Last Year")
                    .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                    .fontWeight(.bold))
                {
                    
                    DonutChartView(chartData: statisticsManager.lastYear().asZoneDonutChartData(propertyName: PropertyViewParamaters[propertyName]?.byZonePropertyName ?? ""),
                                   totalName: PropertyViewParamaters[propertyName]?.totalLabel ?? "Total",
                                   totalValue: statisticsManager.lastYear().formattedValue(propertyName: propertyName))

                }
            }
        }

        .navigationTitle(PropertyViewParamaters[propertyName]?.navigationTitle ?? "Error!")
    }

}

#Preview {
    DetailStatisticBarDonutView(propertyName: "TSS")
}
