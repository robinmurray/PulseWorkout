//
//  ChartView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 26/03/2024.
//

import SwiftUI


struct ChartView: View {
    
    @State var activityRecord: ActivityRecord
    @ObservedObject var activityChartsController: ActivityChartsController
    
    init(activityRecord: ActivityRecord) {
        self.activityRecord = activityRecord
        self.activityChartsController = ActivityChartsController()
    }
    
    var body: some View {
        ZStack {
            if activityChartsController.recordFetchFailed {
                FetchFailedView()
            } else {

                if activityChartsController.buildingChartTraces {
                    ProgressView()
                }
                TabView {
                    ForEach(activityChartsController.chartTraces) {chartData in

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

            
        }
        .onAppear(perform: {
            activityChartsController.buildChartTraces(recordID: activityRecord.recordID) })

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
    static var chartColor: Color = .red
    static var displayPrimaryAverage: Bool = true
    
    static var previews: some View {
        ActivityLineChartView(chartData: chartData)
    }

}


