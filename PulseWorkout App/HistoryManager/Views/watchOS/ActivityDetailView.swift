//
//  ActivityDetailView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 30/06/2023.
//

import SwiftUI
import HealthKit

/*
fileprivate enum NavigationTarget {
    case MapRouteView
    case ChartView
}
*/
struct GraphButtonView: View {
    
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @State var buttonColor: Color
    @State var activityRecord: ActivityRecord
    @ObservedObject var dataCache: DataCache
    

    
    var body: some View {
        
        VStack {
            Spacer()

            Button(action: {
                navigationCoordinator.goToView(targetView: ActivityDetailView.NavigationTarget.ChartView)
            })
            {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(buttonColor)
                    .font(.title2)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            Button(action: {
                navigationCoordinator.goToView(targetView: ActivityDetailView.NavigationTarget.MapRouteView)
            })
            {
                Image(systemName: "map.circle")
                    .foregroundColor(buttonColor)
                    .font(.title2)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            
        }
    }
}

struct ActivityDetailView: View {
    
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @State var activityRecord: ActivityRecord
    @ObservedObject var dataCache: DataCache
    
    @State private var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    enum NavigationTarget {
        case MapRouteView
        case ChartView
    }
    
    var body: some View {
        
        TabView {
            HStack {
                VStack(alignment: .leading) {

                    HStack {
                        Image(systemName:"stopwatch")
                            .foregroundColor(timeByHRColor)
                        Spacer()
                        Text(durationFormatter.string(from: activityRecord.movingTime) ?? "")
                            .foregroundStyle(timeByHRColor)
                            .font(.system(.title3, design: .rounded).lowercaseSmallCaps())
                    }
                    Divider()
                    
                    HStack {
                        Image(systemName: distanceIcon)
                            .foregroundColor(distanceColor)
                        Spacer()
                        Text(distanceFormatter(distance: activityRecord.distanceMeters))
                            .foregroundStyle(distanceColor)
                            .font(.system(.title3, design: .rounded).lowercaseSmallCaps())
                    }
                    Divider()
                    
                    HStack {
                        Image(systemName: speedIcon)
                            .foregroundColor(Color.blue)
                        Spacer()
                        Text(speedFormatter(speed: activityRecord.averageSpeed))
                            .foregroundStyle(.blue)
                            .font(.system(.title3, design: .rounded).lowercaseSmallCaps())
                    }
                    Divider()

                    HStack {
                        Image(systemName: heartRateIcon)
                            .foregroundColor(heartRateColor)
                        Spacer()
                        Text(heartRateFormatter(heartRate: Double(activityRecord.averageHeartRate))
                             + " bpm")
                        .foregroundStyle(heartRateColor)
                        .font(.system(.title3, design: .rounded).lowercaseSmallCaps())
                    }
                    Divider()
                    
                }
            
                GraphButtonView(navigationCoordinator: navigationCoordinator,
                                buttonColor: distanceColor,
                                activityRecord: activityRecord,
                                dataCache: dataCache)

            }
            
            HStack {
                VStack(alignment: .leading) {
                    
                    SummaryMetricView(title: "Moving Time",
                                      value: durationFormatter.string(from: activityRecord.movingTime) ?? "")
                    .foregroundStyle(.yellow)
                    
                    
                    SummaryMetricView(title: "Paused Time",
                                      value: durationFormatter.string(from: activityRecord.pausedTime) ?? "")
                    .foregroundStyle(.yellow)
                    
                    HStack {
                        SummaryMetricView(title: "Elapsed Time",
                                          value: durationFormatter.string(from: activityRecord.elapsedTime) ?? "")
                        .foregroundStyle(.yellow)
                        
                        
                    }
                    
                }
                
                GraphButtonView(navigationCoordinator: navigationCoordinator,
                                buttonColor: timeByHRColor,
                                activityRecord: activityRecord,
                                dataCache: dataCache)
                
            }
            .containerBackground(timeByHRColor.gradient, for: .tabView)
            
            HStack {
                VStack {
                    SummaryMetricView(title: "Average Speed",
                                      value: speedFormatter(speed: activityRecord.averageSpeed))
                    .foregroundStyle(.yellow)
                    
                    SummaryMetricView(title: "Distance",
                                      value: distanceFormatter(distance: activityRecord.distanceMeters))
                    .foregroundStyle(.yellow)
                    
                    SummaryMetricView(title: "Ascent / Descent",
                                      value: (distanceFormatter(distance: activityRecord.totalAscent ?? 0, forceMeters: true)) + " / " +
                                      (distanceFormatter(distance: activityRecord.totalDescent ?? 0, forceMeters: true)))
                    .foregroundStyle(.yellow)
                    
                }
                
                GraphButtonView(navigationCoordinator: navigationCoordinator,
                                buttonColor: .blue,
                                activityRecord: activityRecord,
                                dataCache: dataCache)
                
            }
            .navigationTitle("Distance")
            .containerBackground(.blue.gradient, for: .tabView)
            
            HStack {
                VStack {
                    SummaryMetricView(title: "Average",
                                      value: heartRateFormatter(heartRate: Double(activityRecord.averageHeartRate))
                                         + " bpm")
                    .foregroundStyle(.yellow)
                    
                    SummaryMetricView(title: activityRecord.hiHRLimit == nil ? "Time Over High Limit" : "Time Over High Limit (\(activityRecord.hiHRLimit!))",
                                      value: durationFormatter.string(from: activityRecord.timeOverHiAlarm) ?? "0")
                    .foregroundStyle(.yellow)
                    
                    SummaryMetricView(title: activityRecord.loHRLimit == nil ? "Time Under Low Limit"   : "Time Under Low Limit (\(activityRecord.loHRLimit!))",
                                      value: durationFormatter.string(from: activityRecord.timeUnderLoAlarm) ?? "0")
                    .foregroundStyle(.yellow)
                    
                }
                
                GraphButtonView(navigationCoordinator: navigationCoordinator,
                                buttonColor: heartRateColor,
                                activityRecord: activityRecord,
                                dataCache: dataCache)
                
            }
            .navigationTitle("Heart Rate")
            .containerBackground(heartRateColor.gradient, for: .tabView)
            
            HStack {
                VStack {
                    
                    SummaryMetricView(title: "Average Power",
                                      value: powerFormatter(watts: Double(activityRecord.averagePower)))
                    .foregroundStyle(.yellow)
                    
                    SummaryMetricView(title: "Average Cadence",
                                      value: cadenceFormatter(cadence: Double(activityRecord.averageCadence))
                                        )
                    .foregroundStyle(.yellow)
                    
                    SummaryMetricView(title: "Energy",
                                      value: energyFormatter(energy: activityRecord.activeEnergy))
                    .foregroundStyle(.yellow)
                    
                }
                
                GraphButtonView(navigationCoordinator: navigationCoordinator,
                                buttonColor: powerColor,
                                activityRecord: activityRecord,
                                dataCache: dataCache)
                
            }
            .navigationTitle("Power")
            .containerBackground(powerColor.gradient, for: .tabView)
            
        }
        .tabViewStyle(.verticalPage)
        .navigationTitle {
            Label( activityRecord.startDateLocal.formatted(
                Date.FormatStyle(timeZone: TimeZone(abbreviation: TimeZone.current.abbreviation() ?? "")!)
                .day(.twoDigits)
                .month(.abbreviated)
                .hour(.defaultDigits(amPM: .omitted))
                .minute(.twoDigits)
                ),
                   systemImage: HKWorkoutActivityType( rawValue: activityRecord.workoutTypeId)!.iconImage )
            .foregroundColor(.white)
        }
        .navigationDestination(for: NavigationTarget.self) { pathValue in

            if pathValue == .MapRouteView {

                MapRouteView(activityRecord: activityRecord,
                             dataCache: dataCache)
            }
            else if pathValue == .ChartView {
                
                ChartView(activityRecord: activityRecord,
                          dataCache: dataCache)
            }
            
        }
        .onAppear(perform: {
            // Save any changes if any unsaved records
            dataCache.flushCache(qualityOfService: .userInitiated)
        })
    }


}




struct ActivityDetailView_Previews: PreviewProvider {
    
    static var navigationCoordinator = NavigationCoordinator()
    static var record = ActivityRecord()
    static var dataCache = DataCache()
    
    static var previews: some View {
        if #available(watchOS 10.0, *) {
            ActivityDetailView(navigationCoordinator: navigationCoordinator,
                               activityRecord: record,
                               dataCache: dataCache)
        } else {
            // Fallback on earlier versions
        }
    }
}
