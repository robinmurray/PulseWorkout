//
//  ChartView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 26/03/2024.
//

import SwiftUI
import Charts


struct ChartView: View {
    
    @State var activityRecord: ActivityRecord
    @State private var heartRateTrace: [ChartTracePoint] = []
    
    var body: some View {
        Chart {
            ForEach(heartRateTrace, id: \.elapsedSeconds) { item in
                LineMark(
                    x: .value("Elapsed", item.elapsedSeconds),
                    y: .value("Heart Rate", item.value),
                    series: .value("Trace", "Heart Rate")
                )
                .foregroundStyle(.red)
            }
        }
        .onAppear(perform: {
            heartRateTrace = activityRecord.heartRateTrace(maxPoints: 1000)
            
        })
    }
}

struct ChartView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var activityRecord = ActivityRecord(settingsManager: settingsManager)
    
    static var previews: some View {
        ChartView(activityRecord: activityRecord)
    }

}


