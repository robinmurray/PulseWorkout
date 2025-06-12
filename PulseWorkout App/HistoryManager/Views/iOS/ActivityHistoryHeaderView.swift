//
//  ActivityHistoryHeaderView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 16/11/2024.
//

import SwiftUI
import Charts

struct ActivityHistoryHeaderView: View {
    
    @ObservedObject var statisticsManager = StatisticsManager.shared
    
    var body: some View {

        VStack {
            
        HStack{
                VStack {
                    HStack {
                        Text("This week").bold().foregroundStyle(.blue)
                        Spacer()
                    }
                    




                    HStack {
                        Text("\(Int(statisticsManager.weekActivities[0])) Activities")
                        Spacer()
                    }

                    HStack {
                        Text(durationFormatter(elapsedSeconds: statisticsManager.weekTime[0],
                                               minimizeLength: true))
                        Spacer()
                    }
                    
                    HStack {
                        Text(distanceFormatter(distance: statisticsManager.weekDistance[0]))
                        Spacer()
                    }

                    HStack {
                        Text("\(TSSFormatter(TSS: statisticsManager.weekTSS[0])) TS")
                        Spacer()
                    }
                    
                }
                
                Spacer()
                VStack {
                    HStack {
                        Text("Last Week").bold().foregroundStyle(.blue)
                        Spacer()
                    }
                    
                    HStack {
                        Text("\(Int(statisticsManager.weekActivities[1])) Activities")
                        Spacer()
                    }
                    
                    HStack {
                        Text(durationFormatter(elapsedSeconds: statisticsManager.weekTime[1],
                                               minimizeLength: true))
                        Spacer()
                    }
                    
                    HStack {
                        Text(distanceFormatter(distance: statisticsManager.weekDistance[1]))
                        Spacer()
                    }

                    HStack {
                        Text("\(TSSFormatter(TSS: statisticsManager.weekTSS[1])) TS")
                        Spacer()
                    }
                }

            }
            
        }
    }
}

#Preview {
    ActivityHistoryHeaderView()
}
