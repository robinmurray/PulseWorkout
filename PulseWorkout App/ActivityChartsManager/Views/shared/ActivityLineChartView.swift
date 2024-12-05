//
//  ActivityLineChartView.swift
//  PulseWorkout
//
//  Created by Robin Murray on 05/11/2024.
//

import SwiftUI
import Charts

struct ActivityLineChartView: View {

    var chartData: ActivityChartTraceData
    var showDistanceButton: Bool = true
    @State var useDistanceXAxis: Bool = false
    @State var lastAveVal: Int = 0
    
    func getXAxis( item: ActivityChartTracePoint ) -> Int {
        
        return useDistanceXAxis ? Int(item.distanceMeters) : item.elapsedSeconds
        
    }

    func segmentAverage( item: ActivityChartTracePoint ) -> Double {

        return useDistanceXAxis ? Double(item.primaryValueDistanceSegmentAverage) : item.primaryValueTimeSegmentAverage
        
    }

    func isSegmentMidpoint( item: ActivityChartTracePoint ) -> Bool {
        
        return useDistanceXAxis ? item.distanceSegmentMidpoint : item.timeSegmentMidpoint
        
    }

    
    init(chartData: ActivityChartTraceData) {
        self.chartData = chartData
        self.showDistanceButton = (chartData.tracePoints.map( { $0.distanceMeters } ).max() ?? 0 > 0 )
    }
    
    var body: some View {
        VStack {
            Chart {
                ForEach(chartData.tracePoints, id: \.elapsedSeconds) { item in
                    
                    AreaMark(
                        x: .value("Elapsed", getXAxis(item: item)),
                        y: .value("Background", item.scaledBackgroundValue),
                        series: .value("Trace", "Background"),
                        stacking: .unstacked
                    )
                    .foregroundStyle(Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.1)]))

                    if chartData.displayPrimaryAverage {
                        AreaMark(
                            x: .value("Elapsed", getXAxis(item: item)),
                            y: .value("Primary Value Average",  segmentAverage(item: item)),
                            series: .value("Trace", "Primary Value Average"),
                            stacking: .unstacked
                        )
                        .foregroundStyle(Gradient(colors: [chartData.colorScheme.opacity(0.5), chartData.colorScheme.opacity(0.1)]))
                        
                        if isSegmentMidpoint(item: item) {
                            PointMark(
                                x: .value("Elapsed", getXAxis(item: item)),
                                y: .value("Value", segmentAverage(item: item))
                                )
                            .foregroundStyle(.red.opacity(0))
                            .annotation(position: .bottom,
                                        alignment: .center,
                                        spacing: 10) {

                                Text("\(Int(segmentAverage(item: item)))")
                                    .foregroundStyle(.black)
                                    .font(.footnote)
                                    
                            }
                        }
                    }

                    LineMark(
                        x: .value("Elapsed", getXAxis(item: item)),
                        y: .value("Primary Value", item.primaryValue),
                        series: .value("Trace", "Primary Value")
                    )
                    .foregroundStyle(chartData.colorScheme)
 
                }
            }
            .chartScrollableAxes(.horizontal)
            .chartXVisibleDomain(length: useDistanceXAxis ? chartData.distanceXVisibleDomain : chartData.timeXVisibleDomain)
            .chartYAxis {

                AxisMarks(position: .trailing, values: chartData.primaryAxisMarks)

            }
            .chartXAxis {
                if useDistanceXAxis {
                    AxisMarks(position: .automatic,
                              values: chartData.distanceXAxisMarks ) {
                        value in
                        let meters = value.as(Int.self)!

                        AxisValueLabel {
                            Text(distanceFormatter( distance: Double(meters) ))
                        }
                    }
                }
                else {
                    AxisMarks(position: .automatic,
                              values: chartData.timeXAxisMarks )
                    {
                        value in
                        let seconds = value.as(Int.self)

                        AxisValueLabel {
                            Text(durationFormatter(seconds: seconds ?? 0))
                        }
                    }
                }

            }
            
            // Create axis changing button
            if showDistanceButton {
                VStack{
                    HStack {
                        Spacer()
                        Button {
                            useDistanceXAxis = !useDistanceXAxis
                        } label: {
                            Image(systemName: useDistanceXAxis ? measureIcon : "clock.arrow.circlepath")
                                }.labelStyle(.iconOnly)
                            .buttonStyle(BorderlessButtonStyle())

                    }

                }
            }

        }

    }
    
}


#Preview {
    let chartData: ActivityChartTraceData = ActivityChartTraceData(
        id: "My Chart",
        colorScheme: .red,
        displayPrimaryAverage: true,
        timeXAxisMarks: [0, 60, 120, 180, 240],
        timeXVisibleDomain: 120,
        distanceXAxisMarks: [0, 10, 20, 30, 40],
        distanceXVisibleDomain: 20,
        primaryAxisMarks: [0, 50, 100, 150, 200],
        backgroundAxisMarks: ["A", "B", "C", "D", "E"],
        backgroundDataScaleFactor: 1,
        backgroundDataOffset: 0,
        tracePoints: [
            ActivityChartTracePoint(elapsedSeconds: 0,
                                    distanceMeters: 0,
                                    primaryValue: 20,
                                    primaryValueTimeSegmentAverage: 30,
                                    primaryValueDistanceSegmentAverage: 4,
                                    timeSegmentMidpoint: false,
                                    distanceSegmentMidpoint: false,
                                    backgroundValue: 10,
                                    scaledBackgroundValue: 10),
            ActivityChartTracePoint(elapsedSeconds: 120,
                                    distanceMeters: 5,
                                    primaryValue: 100,
                                    primaryValueTimeSegmentAverage: 40,
                                    primaryValueDistanceSegmentAverage: 6,
                                    timeSegmentMidpoint: true,
                                    distanceSegmentMidpoint: true,
                                    backgroundValue: 8,
                                    scaledBackgroundValue: 8),
            ActivityChartTracePoint(elapsedSeconds: 250,
                                    distanceMeters: 7,
                                    primaryValue: 150,
                                    primaryValueTimeSegmentAverage: 60,
                                    primaryValueDistanceSegmentAverage: 2,
                                    timeSegmentMidpoint: false,
                                    distanceSegmentMidpoint: false,
                                    backgroundValue: 3,
                                    scaledBackgroundValue: 3)
        ])

    
    ActivityLineChartView(chartData: chartData)
}

