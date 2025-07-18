//
//  DetailStatisticBarView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 19/06/2025.
//

import SwiftUI

struct DetailStatisticBarView: View {
    
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

                    StackedBarView(stackedBarData: statisticsManager.thisWeekDayBuckets.asDayOfWeekStackedBarData(propertyName: propertyName),
                                   formatter: propertyValueFormatter(propertyName, shortForm: true))

                }
                
                GroupBox(label: Text("Last Week")
                    .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                    .fontWeight(.bold))
                {

                    StackedBarView(stackedBarData: statisticsManager.lastWeekDayBuckets.asDayOfWeekStackedBarData(propertyName: propertyName),
                                   formatter: propertyValueFormatter(propertyName, shortForm: true))

                }
                
                GroupBox(label: Text("Last 12 Weeks")
                    .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                    .fontWeight(.bold))
                {
                    StackedBarView(stackedBarData: statisticsManager.weekBuckets.asWeekStackedBarData(propertyName: propertyName),
                                   formatter: propertyValueFormatter(propertyName, shortForm: true))
                }
                
                GroupBox(label: Text("By Quarters")
                    .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)
                    .fontWeight(.bold))
                {
                    StackedBarView(stackedBarData: statisticsManager.quarterBuckets.asQuarterStackedBarData(propertyName: propertyName),
                                   formatter: propertyValueFormatter(propertyName, shortForm: true))
                }
                
                
            }
            
        }
        .navigationTitle(PropertyViewParamaters[propertyName]?.navigationTitle ?? "Error!")
    }

}

#Preview {
    DetailStatisticBarView(propertyName: "activities")
}
