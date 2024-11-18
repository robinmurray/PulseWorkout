//
//  ChartView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 05/11/2024.
//

import SwiftUI

struct ChartView: View {
    
    @State var activityRecord: ActivityRecord
    var dataCache: DataCache
    @ObservedObject var activityChartsController: ActivityChartsController
    var chartId: String
    
    init(activityRecord: ActivityRecord, dataCache: DataCache, chartId: String) {
        self.activityRecord = activityRecord
        self.dataCache = dataCache
        self.activityChartsController = ActivityChartsController(dataCache: dataCache)
        self.chartId = chartId
    }
    
    var body: some View {
        ZStack {
            if activityChartsController.recordFetchFailed {
                FetchFailedView()
            } else {
                VStack {
                    
                    if activityChartsController.buildingChartTraces {
                        ProgressView()
                    }
                    else {
                        if activityChartsController.chartTraces.first(where: { $0.id == chartId } ) == nil {
                            Text("No Data")
                        }
                        else {
                            ActivityLineChartView(chartData: activityChartsController.chartTraces.first(where: { $0.id == chartId })! )
                        }
                        
                    }
                }


            }
            
        }
        .onAppear(perform: {
            activityChartsController.buildChartTraces(recordID: activityRecord.recordID) })
        .navigationTitle(chartId)

    }
}

/*
#Preview {
    ChartView()
}
*/
