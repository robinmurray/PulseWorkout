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

    
    
    var body: some View {
        
        VStack {

            StackedBarView(stackedBarData: stackedBarData)
            
            DonutChartView(chartData: donutChartData,
                           totalName: donutChartTotalName,
                           totalValue: donutChartTotalValue)
        }


    }
}

#Preview {
    let testBarData: [StackedBarChartDataPoint] =
    [StackedBarChartDataPoint(index: "M", type: "low aerobic", value: 10),
     StackedBarChartDataPoint(index: "M", type: "high aerobic", value: 30),
     StackedBarChartDataPoint(index: "M", type: "anaerobic", value: 5),
     StackedBarChartDataPoint(index: "T", type: "low aerobic", value: 15),
     StackedBarChartDataPoint(index: "T", type: "high aerobic", value: 20),
     StackedBarChartDataPoint(index: "T", type: "anaerobic", value: 10)
     ]
    let testDonutData: [DonutChartDataPoint] =
    [DonutChartDataPoint(name: "Low Aerobic", value: 10, formattedValue: "10"),
     DonutChartDataPoint(name: "High Aerobic", value: 20, formattedValue: "20"),
     DonutChartDataPoint(name: "Anaerobic", value: 5, formattedValue: "5")]

    
    StackedBarAndDonutView(stackedBarData: testBarData,
                           donutChartData: testDonutData,
                           donutChartTotalName: "Total",
                           donutChartTotalValue: "999")
}
