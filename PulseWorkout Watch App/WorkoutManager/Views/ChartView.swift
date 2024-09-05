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
/*                    Chart {
                        ForEach(dataCache.altitudeTrace, id: \.elapsedSeconds) { item in
                            AreaMark(
                                x: .value("Elapsed", item.elapsedSeconds),
                                y: .value("Altitude", item.value),
                                series: .value("Trace", "Altitude")
                            )
                            .foregroundStyle(Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.1)]))
                        }
                    }
                    .chartXAxis(Visibility.hidden)
 */
//                    .chartYAxis(Visibility.hidden)
                    
                    Chart {
                        ForEach(dataCache.heartRateChartData.tracePoints, id: \.elapsedSeconds) { item in

                            AreaMark(
                                x: .value("Elapsed", item.elapsedSeconds),
                                y: .value("Altitude", item.altitude),
                                series: .value("Trace", "Altitude")
                            )
                            .foregroundStyle(Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.1)]))
//                            .foregroundStyle(by: .value("Value", "Altitude"))

                            LineMark(
                                x: .value("Elapsed", item.elapsedSeconds),
                                y: .value("Heart Rate", item.heartRate),
                                series: .value("Trace", "Heart Rate")
                            )
                            .foregroundStyle(.red)
//                            .foregroundStyle(by: .value("Value", "Heart Rate"))

                        }
                    }
                    .chartYAxis {

                        AxisMarks(position: .trailing, values: [0, 50, 100, 150, 200])

/*
                        let alts = dataCache.heartRateTrace.map { $0.altitude }
                        let min = alts.min() ?? 0
                        let max = alts.max() ?? 200
                        let altsStride = Array(stride(from: min,
                                                                through: max,
                                                                by: (max - min)/4))
 */
                         
/** FIX!
                        AxisMarks(position: .trailing, values: altsStride) { axis in
                            AxisGridLine()
                            let value = costsStride[axis.index]
                            AxisValueLabel("\(String(format: "%.2F", value)) kr", centered: false)
                        }
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 5))
**/
                    }
                    
                }
                .navigationTitle {
                    Text("Heart Rate")
                        .foregroundStyle(.red)
                }
                .containerBackground(.red.gradient, for: .tabView)
                
                VStack {
                    Chart {
                        ForEach(dataCache.altitudeTrace, id: \.elapsedSeconds) { item in
                            AreaMark(
                                x: .value("Elapsed", item.elapsedSeconds),
                                y: .value("Altitude", item.value),
                                series: .value("Trace", "Altitude")
                            )
                            .foregroundStyle(Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.1)]))
                        }

                        ForEach(dataCache.totalAscentTrace, id: \.elapsedSeconds) { item in
                            LineMark(
                                x: .value("Elapsed", item.elapsedSeconds),
                                y: .value("Ascent", item.value),
                                series: .value("Trace", "Ascent")
                            )
                            .foregroundStyle(Color.blue)
                        }

                        ForEach(dataCache.totalDescentTrace, id: \.elapsedSeconds) { item in
                            LineMark(
                                x: .value("Elapsed", item.elapsedSeconds),
                                y: .value("Descent", item.value),
                                series: .value("Trace", "Descent")
                            )
                            .foregroundStyle(Color.indigo)
                        }
                    }
                }
                .navigationTitle("Ascent/Descent")
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


