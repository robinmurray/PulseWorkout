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
                        Text("Activities: \(statisticsManager.thisWeek().formattedValue(propertyName: "activities"))")
                        Spacer()
                    }

                    HStack {
                        Text(statisticsManager.thisWeek().formattedValue(propertyName: "time"))
                        Spacer()
                    }
                    
                    HStack {
                        Text(statisticsManager.thisWeek().formattedValue(propertyName: "distanceMeters"))
                        Spacer()
                    }

                    HStack {
                        Text("TSS: \(statisticsManager.thisWeek().formattedValue(propertyName: "TSS"))")

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
                        Text("Activities: \(statisticsManager.lastWeek().formattedValue(propertyName: "activities"))")
                        Spacer()
                    }
                    
                    HStack {
                        Text(statisticsManager.lastWeek().formattedValue(propertyName: "time"))
                        Spacer()
                    }
                    
                    HStack {
                        Text(statisticsManager.lastWeek().formattedValue(propertyName: "distanceMeters"))
                        Spacer()
                    }

                    HStack {
                        Text("TSS: \(statisticsManager.lastWeek().formattedValue(propertyName: "TSS"))")


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
