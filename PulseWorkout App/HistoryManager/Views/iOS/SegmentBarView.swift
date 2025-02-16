//
//  SegmentBarView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 14/02/2025.
//

import SwiftUI
import Charts

struct SegmentChartData: Identifiable {
    let id = UUID()
    let startTime: Int
    let value: Int
}

struct SegmentBarView: View {
    
    var segmentValues: [Int]
    var segmentSize: Int
    var horizontalLineVal: Int?
    var colourScheme: Color
    
    
    var body: some View {
        
        VStack {
            Chart(segmentValues.enumerated().map( { (index, value) in
                SegmentChartData(startTime: segmentSize * (index + 1),
                                 value: value) } ) )
            { chartPoint in

                BarMark(
                    x: .value("Elapsed", elapsedTimeFormatter( elapsedSeconds: Double(chartPoint.startTime), minimizeLength: true )),
                    y: .value("Background", chartPoint.value),
                   stacking: .unstacked
                    
                )
                .foregroundStyle(Gradient(colors: [colourScheme.opacity(0.5), colourScheme.opacity(0.1)]))

                if let hLine = horizontalLineVal {
                    RuleMark(
                        y: .value("Average", hLine)
                    )
                    .foregroundStyle(colourScheme)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 10]))
                }

            }
            
            Divider()
        }

    }
}

#Preview {
    SegmentBarView(segmentValues: [10, 20, 40, 20], segmentSize: 300, horizontalLineVal: 30, colourScheme: Color.red)
}
