//
//  ChartView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 26/03/2024.
//

import SwiftUI
import Charts
import CloudKit

struct ChartView: View {
    
    @State var activityRecord: ActivityRecord
    @ObservedObject var dataCache: DataCache
    
    var body: some View {
        ZStack {
            if dataCache.buildingChartTraces {
                ProgressView()
            }
            TabView {
                ZStack {
    
                    Chart {
                        ForEach(dataCache.heartRateChartData.tracePoints, id: \.elapsedSeconds) { item in

                            AreaMark(
                                x: .value("Elapsed", item.elapsedSeconds),
                                y: .value("Altitude", item.scaledAltitude),
                                series: .value("Trace", "Altitude")
                            )
                            .foregroundStyle(Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.1)]))

                            LineMark(
                                x: .value("Elapsed", item.elapsedSeconds),
                                y: .value("Heart Rate", item.heartRate),
                                series: .value("Trace", "Heart Rate")
                            )
                            .foregroundStyle(.red)

                        }
                    }
                    .chartScrollableAxes(.horizontal)
                    .chartYAxis {

                        AxisMarks(position: .trailing, values: dataCache.heartRateChartData.heartRateAxisMarks)

                    }
                    
                }
                .navigationTitle {
                    Text("Heart Rate")
                        .foregroundStyle(.red)
                }
                .containerBackground(.red.gradient, for: .tabView)
                
                VStack {
                    Chart {
                        ForEach(dataCache.totalAscentTrace.tracePoints, id: \.elapsedSeconds) { item in
                            AreaMark(
                                x: .value("Elapsed", item.elapsedSeconds),
                                y: .value("Altitude", item.scaledAltitude),
                                series: .value("Trace", "Altitude")
                            )
                            .foregroundStyle(Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.1)]))


                            LineMark(
                                x: .value("Elapsed", item.elapsedSeconds),
                                y: .value("Ascent", item.ascent),
                                series: .value("Trace", "Ascent")
                            )
                            .foregroundStyle(Color.blue)
                        }

                    }
                    .chartScrollableAxes(.horizontal)
                    .chartYAxis {

                        AxisMarks(position: .trailing, values: dataCache.totalAscentTrace.ascentAxisMarks)

                    }
                }
                .navigationTitle("Ascent")
                .containerBackground(.blue.gradient, for: .tabView)
                
            }
            .tabViewStyle(.verticalPage)

        }
        .onAppear(perform: {
            dataCache.buildChartTraces(recordID: activityRecord.recordID)
            
        })
    }
}

struct ChartView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var activityRecord = ActivityRecord(settingsManager: settingsManager)
    static var dataCache = DataCache()
    
    static var previews: some View {
        ChartView(activityRecord: activityRecord, dataCache: dataCache)
    }

}


