//
//  ChartView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 26/03/2024.
//

import SwiftUI
import Charts
import CloudKit



struct ActivityLineChartView: View {

    var chartData: ActivityChartTraceData
    @State var useDistanceXAxis: Bool = false
    
    func getXAxis( item: ActivityChartTracePoint ) -> Int {
        return useDistanceXAxis ? Int(item.distanceMeters) : item.elapsedSeconds
    }
    
    func getDistanceAxisMarks(values: [Int]) -> any AxisContent {
        return AxisMarks( values: chartData.distanceXAxisMarks )  as! (any AxisContent)
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
                            y: .value("Primary Value Average",  item.primaryValueSegmentAverage),
                            series: .value("Trace", "Primary Value Average"),
                            stacking: .unstacked
                        )
                        .foregroundStyle(Gradient(colors: [chartData.colorScheme.opacity(0.5), chartData.colorScheme.opacity(0.1)]))
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
                    AxisMarks( values: chartData.distanceXAxisMarks ) {
                        value in
                        let meters = value.as(Int.self)!

                        AxisValueLabel {
                            Text(distanceFormatter( distance: Double(meters) ))
                        }
                    }
                }
                else {
                    AxisMarks(values: chartData.timeXAxisMarks )
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
            // FIX - only display button if distance data exists
            VStack{
                HStack {
                    Spacer()
                    Button {
                        useDistanceXAxis = !useDistanceXAxis
                    } label: {
                        Image(systemName: useDistanceXAxis ? "ruler" : "clock.arrow.circlepath")
                            }.labelStyle(.iconOnly)
                        .buttonStyle(BorderlessButtonStyle())

                }

            }

        }

    }
    
}

struct ChartView: View {
    
    @State var activityRecord: ActivityRecord
    @ObservedObject var dataCache: DataCache
    
    var body: some View {
        ZStack {
            if dataCache.buildingChartTraces {
                ProgressView()
            }
            TabView {
                ForEach([dataCache.heartRateChartData,
                         dataCache.powerTrace,
                         dataCache.totalAscentTrace]) {chartData in

                    VStack {
                        ActivityLineChartView(chartData: chartData)
                    }
     
                    .navigationTitle {
                        Text(chartData.id)
                            .foregroundStyle(chartData.colorScheme)
                    }
                    .containerBackground(chartData.colorScheme.gradient, for: .tabView)
                    
                }

            }
            .tabViewStyle(.verticalPage)
            
        }
        .onAppear(perform: {
            dataCache.buildChartTraces(recordID: activityRecord.recordID) })
    }
}

struct ChartView_Previews: PreviewProvider {
    
    static var chartData: ActivityChartTraceData = ActivityChartTraceData(
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
                                    primaryValueSegmentAverage: 15,
                                    backgroundValue: 10,
                                    scaledBackgroundValue: 10),
            ActivityChartTracePoint(elapsedSeconds: 120,
                                    distanceMeters: 5,
                                    primaryValue: 100,
                                    primaryValueSegmentAverage: 17,
                                    backgroundValue: 8,
                                    scaledBackgroundValue: 8),
            ActivityChartTracePoint(elapsedSeconds: 250,
                                    distanceMeters: 7,
                                    primaryValue: 150,
                                    primaryValueSegmentAverage: 16,
                                    backgroundValue: 3,
                                    scaledBackgroundValue: 3)
        ])
    static var chartColor: Color = .red
    static var displayPrimaryAverage: Bool = true
    
    static var previews: some View {
        ActivityLineChartView(chartData: chartData)
    }

}


