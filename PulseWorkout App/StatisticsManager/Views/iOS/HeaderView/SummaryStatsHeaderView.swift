//
//  SummaryStatsHeaderView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 15/08/2025.
//

import SwiftUI

struct SummaryStatsHeaderView: View {
    
    @ObservedObject var statisticsManager = StatisticsManager.shared
    
    var body: some View {
        
        GeometryReader { geometry in
            let padWidth: CGFloat = 1
            let frameWidth: CGFloat = max(((geometry.size.width - (8 * padWidth)) / 4 ) - 4, 10)
        
            HStack {

                
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(activitiesColor, lineWidth: 1)
                    
                    VStack {
                            Text("Activities")
                            .font(.caption)
                            .bold()
                        
                        BarView(stackedBarChartData: statisticsManager.weekBuckets.asWeekStackedBarChartData(propertyName: "activities", filterList: ["last", "this"]))
                                                
                    }
                }
                .frame(width: frameWidth)

                Spacer()
                
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(TSSColor, lineWidth: 1)
                    VStack {
                        VStack {
                            Text("Load")
                                .font(.caption)
                                .bold()
 
                            BarView(stackedBarChartData: statisticsManager.weekBuckets.asWeekStackedBarChartData(propertyName: "TSSByZone", filterList: ["last", "this"]))
                        }
                        
                    }
                }
                .frame(width: frameWidth)

                Spacer()
                
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(distanceColor, lineWidth: 1)
                    
                    VStack {
                        Text("Distance")
                            .font(.caption)
                            .bold()
 
                        BarView(stackedBarChartData: statisticsManager.weekBuckets.asWeekStackedBarChartData(propertyName: "distanceMeters", filterList: ["last", "this"]))
                    }
                }
                .frame(width: frameWidth)

                Spacer()
                
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(timeByHRColor, lineWidth: 1)
                    
                    VStack {
                        Text("Time")
                            .font(.caption)
                            .bold()

                        BarView(stackedBarChartData: statisticsManager.weekBuckets.asWeekStackedBarChartData(propertyName: "timeByZone", filterList: ["last", "this"]))
                    }
                }
                .frame(width: frameWidth)

                Spacer()

            }
            .frame(height: 120)
            
    }
    .frame(height: 120)
    }
}

#Preview {
    SummaryStatsHeaderView()
}
