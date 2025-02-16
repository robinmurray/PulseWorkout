//
//  DonutChartView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 14/02/2025.
//

import SwiftUI
import Charts


struct DonutChartDataPoint : Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let formattedValue: String
}


struct DonutChartView: View {
    
    var chartData: [DonutChartDataPoint]
    var totalName: String
    var totalValue: String
    
    
    var body: some View {
        
        VStack {
            ZStack {

                // The donut chart
                Chart(chartData) { dataPoint in
                    SectorMark(
                        angle: .value(
                            Text(verbatim: dataPoint.name),
                            dataPoint.value
                        ),
                        innerRadius: .ratio(0.618),
                        angularInset: 8
                    )
                    .foregroundStyle(
                        by: .value(
                            "Name",
                            dataPoint.name
                        )
                    )
                    .cornerRadius(6)
                    .annotation(position: .overlay) {
                        if dataPoint.value > 0 {
                            Text(dataPoint.formattedValue).bold()
                        }
                        
                    }
                }
                .frame(width: 300, height: 300)
                
                // The text in the centre
                VStack(alignment:.center) {
                    Text(totalName).bold()
                    Text(totalValue).bold()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                
                    
            }
            Divider()
        }

    }
}

#Preview {
    DonutChartView(chartData: [DonutChartDataPoint(name: "Low Aerobic", value: 10, formattedValue: "10"),
                               DonutChartDataPoint(name: "High Aerobic", value: 40, formattedValue: "40"),
                               DonutChartDataPoint(name: "Anaerobic", value: 7, formattedValue: "7")], totalName: "Total Load", totalValue: "57.0")
}
