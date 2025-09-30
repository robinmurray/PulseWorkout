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
 
            ScrollView {
                GroupBox(label: Text("This Week")
                    .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                    .fontWeight(.bold))
                {

                    BarAndDonutView(
                        stackedBarChartData: statisticsManager.thisWeekDayBuckets.asDayOfWeekStackedBarChartData(propertyName: propertyName))

                }
                
                GroupBox(label: Text("Last Week")
                    .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                    .fontWeight(.bold))
                {
                    
                    BarAndDonutView(
                        stackedBarChartData: statisticsManager.lastWeekDayBuckets.asDayOfWeekStackedBarChartData(propertyName: propertyName))
                }
                
                GroupBox(label: Text("Last 12 Weeks")
                    .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                    .fontWeight(.bold))
                {
      
                    BarAndDonutView(
                        stackedBarChartData: statisticsManager.weekBuckets.asWeekStackedBarChartData(propertyName: propertyName))
                    
                }
                
                GroupBox(label: Text("By Quarters")
                    .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                    .fontWeight(.bold))
                {
                    
                    BarAndDonutView(
                        stackedBarChartData: statisticsManager.quarterBuckets.asQuarterStackedBarChartData(propertyName: propertyName))
                    
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
