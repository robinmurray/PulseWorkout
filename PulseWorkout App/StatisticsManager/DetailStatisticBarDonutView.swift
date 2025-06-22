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
            GroupBox(label: Text("This Week")
                .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                .fontWeight(.bold))
            {

                StackedBarView(stackedBarData: statisticsManager.thisWeekDayBuckets.asDayOfWeekStackedBarData(propertyName: propertyName))

            }
            
            GroupBox(label: Text("Last Week")
                .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                .fontWeight(.bold))
            {

                StackedBarView(stackedBarData: statisticsManager.lastWeekDayBuckets.asDayOfWeekStackedBarData(propertyName: propertyName))

            }
            
            GroupBox(label: Text("Last 12 Weeks")
                .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                .fontWeight(.bold))
            {
                StackedBarView(stackedBarData: statisticsManager.weekBuckets.asWeekStackedBarData(propertyName: propertyName))            }
            
            GroupBox(label: Text("By Quarters")
                .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                .fontWeight(.bold))
            {
                StackedBarView(stackedBarData: statisticsManager.quarterBuckets.asQuarterStackedBarData(propertyName: propertyName))
            }
            
            
        }
        .navigationTitle(PropertyViewParamaters[propertyName]?.navigationTitle ?? "Error!")
    }

}

#Preview {
    DetailStatisticBarDonutView(propertyName: "TSS")
}
