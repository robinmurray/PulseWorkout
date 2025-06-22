//
//  StackedBarView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 07/06/2025.
//

import SwiftUI
import Charts

struct StackedBarChartDataPoint: Identifiable {
    let id = UUID()
    var index: String
    var type: String
    var value: Double
}

struct StackedBarView: View {
    
    var stackedBarData: [StackedBarChartDataPoint]
    
    var body: some View {
        Chart {
            ForEach(stackedBarData) { dataPoint in
                BarMark(
                    x: .value("Shape Type", dataPoint.index),
                    y: .value("Total Count", dataPoint.value)
                )
                .foregroundStyle(by: .value("Shape Color", dataPoint.type))
            }
        }
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(stroke: StrokeStyle(lineWidth: 0))
        }

    }
}

#Preview {
    
    let testData: [StackedBarChartDataPoint] =
    [StackedBarChartDataPoint(index: "M", type: "low aerobic", value: 10),
     StackedBarChartDataPoint(index: "M", type: "high aerobic", value: 30),
     StackedBarChartDataPoint(index: "M", type: "anaerobic", value: 5),
     StackedBarChartDataPoint(index: "T", type: "low aerobic", value: 15),
     StackedBarChartDataPoint(index: "T", type: "high aerobic", value: 20),
     StackedBarChartDataPoint(index: "T", type: "anaerobic", value: 10)
     ]
    StackedBarView(stackedBarData: testData)
}
