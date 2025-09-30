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
    var stackIndex: String
    var stackCategory: String
    var value: Double
    var stackCategoryColor: Color
}


var powerZoneColors: [String: Color] = ["Low Aerobic" : .blue,
                                        "High Aerobic" : .green,
                                        "Anaerobic" : .orange]

func getColorForPowerZone(label: String) -> Color {
    return powerZoneColors[label] ?? .pink
}


// REIMPLEMENT THIS FOR STACKEDBARCHARTDATA
struct StackedBarView: View {
    
    var stackedBarData: [StackedBarChartDataPoint]
    var formatter: (Double) -> String
    
    var body: some View {
        Chart {
            ForEach(stackedBarData) { dataPoint in
                BarMark(
                    x: .value("Index", dataPoint.stackIndex),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle(dataPoint.stackCategoryColor)
//                .foregroundStyle(by: .value("Type", dataPoint.stackCategory))
                .annotation(position: .top, spacing: 10) {
                    let summedValues = stackedBarData.filter( {$0.stackIndex == dataPoint.stackIndex} ).reduce(0) { result, dp
                        in
                        result + dp.value }
                    
                    let rotationDegrees = Set(stackedBarData.map({$0.stackIndex})).count > 8 ? 300 : 0
                    if dataPoint.stackCategory == stackedBarData.filter( {$0.stackIndex == dataPoint.stackIndex} ).last!.stackCategory {
                        Text(formatter(summedValues))
                            .rotationEffect(.degrees(Double(rotationDegrees)))
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(stroke: StrokeStyle(lineWidth: 0))
        }
        .chartYAxis(.hidden)

    }
}

#Preview {
    
    let testData: [StackedBarChartDataPoint] =
    [StackedBarChartDataPoint(stackIndex: "M", stackCategory: "low aerobic", value: 10, stackCategoryColor: .blue),
     StackedBarChartDataPoint(stackIndex: "M", stackCategory: "high aerobic", value: 30, stackCategoryColor: .green),
     StackedBarChartDataPoint(stackIndex: "M", stackCategory: "anaerobic", value: 5, stackCategoryColor: .orange),
     StackedBarChartDataPoint(stackIndex: "T", stackCategory: "low aerobic", value: 15, stackCategoryColor: .blue),
     StackedBarChartDataPoint(stackIndex: "T", stackCategory: "high aerobic", value: 20, stackCategoryColor: .green),
     StackedBarChartDataPoint(stackIndex: "T", stackCategory: "anaerobic", value: 10, stackCategoryColor: .orange)
     ]
    StackedBarView(stackedBarData: testData,
                   formatter: propertyValueFormatter("TSS"))
}
