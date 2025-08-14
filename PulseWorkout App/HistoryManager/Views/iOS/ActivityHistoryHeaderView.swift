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
            //            Text("Week Statistics")
            Divider()
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
                                
                                StackedBarView(stackedBarData: statisticsManager.weekBuckets.asWeekStackedBarData(propertyName: "activities", filterList: ["last", "this"]),
                                               formatter: propertyValueFormatter("activities", shortForm: true))
                                
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
                                    
                                    StackedBarView(stackedBarData: statisticsManager.weekBuckets.asWeekStackedBarData(propertyName: "TSSByZone", filterList: ["last", "this"]),
                                                   formatter: propertyValueFormatter("TSS", shortForm: true))
                                    
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
                                
                                StackedBarView(stackedBarData: statisticsManager.weekBuckets.asWeekStackedBarData(propertyName: "distanceMeters", filterList: ["last", "this"]),
                                               formatter: propertyValueFormatter("distanceMeters", shortForm: true))
                                
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
                                
                                StackedBarView(stackedBarData: statisticsManager.weekBuckets.asWeekStackedBarData(propertyName: "timeByZone", filterList: ["last", "this"]),
                                               formatter: propertyValueFormatter("timeByZone", shortForm: true))
                                
                            }
                        }
                        .frame(width: frameWidth)

                        Spacer()

                    }
                    .frame(height: 120)
                    
            }

            .frame(height: 120)

        }
        .padding()
        .background(.gray.opacity(0.25))
 
    }
}

#Preview {
    ActivityHistoryHeaderView()
}
