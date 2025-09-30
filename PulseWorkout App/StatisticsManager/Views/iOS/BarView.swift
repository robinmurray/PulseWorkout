//
//  BarView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 23/09/2025.
//

import SwiftUI
import Charts


struct BarView: View {
    
    var stackedBarChartData: StackedBarChartData
    
    var body: some View {
        Chart {
            ForEach(stackedBarChartData.dataPoints) { dataPoint in
                BarMark(
                    x: .value("Index", dataPoint.category ?? ""),
                    y: .value("Value", dataPoint.value)
                )
                .foregroundStyle( stackedBarChartData.categoryColor(subCategory: dataPoint.subCategory))
                .annotation(position: .top, spacing: 10) {

                    let rotationDegrees = Set(stackedBarChartData.dataPoints.map({$0.category})).count > 8 ? 300 : 0
                    if dataPoint.subCategory == stackedBarChartData.dataPoints.filter( {$0.category == dataPoint.category} ).last!.subCategory {
                        
                        Text(stackedBarChartData.formattedTotalForCategory(category: dataPoint.category!))
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

/*
#Preview {
    BarView()
}
*/
