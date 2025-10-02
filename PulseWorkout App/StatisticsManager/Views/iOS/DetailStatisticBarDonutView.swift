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
                    
                    DonutView(stackedBarChartData: statisticsManager.yearBuckets.asYearStackedBarChartData(propertyName: propertyName, filterList: ["this"]))
                    
                }
                
                GroupBox(label: Text("Last Year")
                    .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                    .fontWeight(.bold))
                {
                    
                    DonutView(stackedBarChartData: statisticsManager.yearBuckets.asYearStackedBarChartData(propertyName: propertyName, filterList: ["last"]))
                    


                }
            }
        }

        .navigationTitle(PropertyViewParamaters[propertyName]?.navigationTitle ?? "Error!")
    }

}

#Preview {
    DetailStatisticBarDonutView(propertyName: "TSS")
}
