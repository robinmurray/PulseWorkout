//
//  StackedBarAndDonutView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 20/06/2025.
//

import SwiftUI
import Charts


struct StackedBarAndDonutView: View {
    var stackedBarData: [StackedBarChartDataPoint]
    var donutChartData: [DonutChartDataPoint]
    var donutChartTotalName: String
    var donutChartTotalValue: String
    var formatter: (Double) -> String
    
    
    var body: some View {
        
        VStack {

            StackedBarView(stackedBarData: stackedBarData,
                           formatter: formatter)
            
            DonutChartView(chartData: donutChartData,
                           totalName: donutChartTotalName,
                           totalValue: donutChartTotalValue)
        }


    }
}

#Preview {
    let testBarData: [StackedBarChartDataPoint] =
    [StackedBarChartDataPoint(stackIndex: "M", stackCategory: "low aerobic", value: 10, stackCategoryColor: .blue),
     StackedBarChartDataPoint(stackIndex: "M", stackCategory: "high aerobic", value: 30, stackCategoryColor: .green),
     StackedBarChartDataPoint(stackIndex: "M", stackCategory: "anaerobic", value: 5, stackCategoryColor: .orange),
     StackedBarChartDataPoint(stackIndex: "T", stackCategory: "low aerobic", value: 15, stackCategoryColor: .blue),
     StackedBarChartDataPoint(stackIndex: "T", stackCategory: "high aerobic", value: 20, stackCategoryColor: .green),
     StackedBarChartDataPoint(stackIndex: "T", stackCategory: "anaerobic", value: 10, stackCategoryColor: .orange)
     ]
    let testDonutData: [DonutChartDataPoint] =
    [DonutChartDataPoint(name: "Low Aerobic", color: .blue, value: 10, formattedValue: "10"),
     DonutChartDataPoint(name: "High Aerobic", color: .green, value: 20, formattedValue: "20"),
     DonutChartDataPoint(name: "Anaerobic", color: .orange, value: 5, formattedValue: "5")]

    
    StackedBarAndDonutView(stackedBarData: testBarData,
                           donutChartData: testDonutData,
                           donutChartTotalName: "Total",
                           donutChartTotalValue: "999",
                           formatter: propertyValueFormatter("TSS"))
}
