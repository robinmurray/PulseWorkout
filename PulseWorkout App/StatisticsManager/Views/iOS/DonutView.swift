//
//  DonutView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 24/09/2025.
//

import SwiftUI
import Charts

struct DonutView: View {
    
    var stackedBarChartData: StackedBarChartData

    var body: some View {
        
        VStack {
            ZStack {

                // The donut chart
                Chart(stackedBarChartData.totalsBySubcategory) { dataPoint in
                    SectorMark(
                        angle: .value(
                            Text(verbatim: stackedBarChartData.subCategoryLabel(subCategory: dataPoint.subCategory)),
                            dataPoint.value
                        ),
                        innerRadius: .ratio(0.618),
                        angularInset: 8
                    )
                    .foregroundStyle(
                        by: .value(
                            "Name",
                            stackedBarChartData.subCategoryLabel(subCategory: dataPoint.subCategory))

                    )

                    .cornerRadius(6)
                    .annotation(position: .overlay) {
                        if dataPoint.value > 0 {
                            Text(dataPoint.formattedValue).bold()
                        }
                        
                    }
                }
                // Set color for each data in the chart
                .chartForegroundStyleScale(
                domain: stackedBarChartData.allCategoryLabels(),
                range: stackedBarChartData.allCategoryColors()
                )
                .frame(width: 300, height: 300)
                
                // The text in the centre
                VStack(alignment:.center) {
                    Text(stackedBarChartData.totalName).bold()
                    Text(stackedBarChartData.formattedTotal()).bold()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                
                    
            }
            Divider()
        }

    }
}

/*
#Preview {
    DonutView()
}
*/
