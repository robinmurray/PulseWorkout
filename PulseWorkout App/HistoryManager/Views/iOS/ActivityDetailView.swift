//
//  SwiftUIView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 03/11/2024.
//

import SwiftUI
import HealthKit


struct ActivityDetailView: View {
    
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @ObservedObject var activityRecord: ActivityRecord
    @ObservedObject var dataCache: DataCache
    
    enum NavigationTarget {
        case MapRouteView
        case ChartViewAscent
        case ChartViewHR
        case ChartViewPower
        case ChartViewCadence

    }
    
    @State private var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    
    var body: some View {

        ScrollView {
            GroupBox(label: ActivityHeaderView(activityRecord: activityRecord))
            {
                Button(action: {
                    navigationCoordinator.goToView(targetView: NavigationTarget.MapRouteView)
                })
                {
                    Spacer()
                    Image(uiImage: activityRecord.mapSnapshotImage ?? UIImage(systemName: "map")!.withTintColor(.blue))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 360, height: 180, alignment: .topLeading)
                    Spacer()
                }
                .buttonStyle(BorderlessButtonStyle())

            }

            GroupBox(label:
                        VStack {
                HStack {
                    Image(systemName: "stopwatch")
                        .font(.title2)
                        .frame(width: 40, height: 40)
                    Text("Activity Time")
                    Spacer()

                }
                .foregroundColor(.green)
                
                Divider()
            }
            )
            {
                VStack
                {
                    
                    SummaryMetricView(title: "Moving Time",
                                      value: durationFormatter.string(from: activityRecord.movingTime) ?? "")
                    
                    SummaryMetricView(title: "Paused Time",
                                      value: durationFormatter.string(from: activityRecord.pausedTime) ?? "")
                    
                    
                    SummaryMetricView(title: "Elapsed Time",
                                      value: durationFormatter.string(from: activityRecord.elapsedTime) ?? "")
                    
                }
            }

            GroupBox(label:
                VStack {
                HStack {
                    Image(systemName: speedIcon)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                    Text("Speed / Distance")
                    Spacer()
                }
                
                Divider()
                    
                }
                .foregroundColor(distanceColor)
            )
            {
                VStack {
                    
                    SummaryMetricView(title: "Average Speed",
                                      value: speedFormatter(speed: activityRecord.averageSpeed))
                    
                    SummaryMetricView(title: "Distance",
                                      value: distanceFormatter(distance: activityRecord.distanceMeters))
                    
                    
                    Button(action: {
                        navigationCoordinator.goToView(targetView: NavigationTarget.ChartViewAscent)
                    })
                    {
                        HStack{
                            SummaryMetricView(title: "Ascent / Descent",
                                              value: (distanceFormatter(distance: activityRecord.totalAscent ?? 0, forceMeters: true)) + " / " +
                                              (distanceFormatter(distance: activityRecord.totalDescent ?? 0, forceMeters: true)))
                            
                            Spacer()
                            
                            Image(systemName: "chart.xyaxis.line")
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(distanceColor)
                        }
                    
                    }
                    .buttonStyle(BorderlessButtonStyle())
                         
                }
                .foregroundStyle(.foreground)
            }
            


            GroupBox(label:
                VStack {
                HStack {
                    Image(systemName: heartRateIcon)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                    Text("Heart Rate")
                    Spacer()
                }
                
                Divider()
                    
                }
                .foregroundColor(heartRateColor)
            )
            {
                VStack {

                    Button(action: {
                        navigationCoordinator.goToView(targetView: NavigationTarget.ChartViewHR)
                    })
                    {
                        HStack{
                            SummaryMetricView(title: "Average",
                                              value: activityRecord.averageHeartRate
                                .formatted(.number.precision(.fractionLength(0))) + " bpm")
                            Spacer()
                            Image(systemName: "chart.xyaxis.line")
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(heartRateColor)
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    
                    SummaryMetricView(title: activityRecord.hiHRLimit == nil ? "Time Over High Limit" : "Time Over High Limit (\(activityRecord.hiHRLimit!))",
                                      value: durationFormatter.string(from: activityRecord.timeOverHiAlarm) ?? "0")
                    
                    SummaryMetricView(title: activityRecord.loHRLimit == nil ? "Time Under Low Limit"   : "Time Under Low Limit (\(activityRecord.loHRLimit!))",
                                      value: durationFormatter.string(from: activityRecord.timeUnderLoAlarm) ?? "0")
                }
                .foregroundStyle(.foreground)
            }

            GroupBox(label:
                VStack {
                HStack {
                    Image(systemName: powerIcon)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                    Text("Power / Cadence")
                    Spacer()
                }
                
                Divider()
                    
                }
                .foregroundColor(powerColor)
            )
            {
                VStack {

                    Button(action: {
                        navigationCoordinator.goToView(targetView: NavigationTarget.ChartViewPower)
                    })
                    {
                        HStack{
                            SummaryMetricView(title: "Average Power",
                                              value: Measurement(value: Double(activityRecord.averagePower),
                                                                 unit: UnitPower.watts)
                                                .formatted(.measurement(width: .abbreviated,
                                                                        usage: .asProvided)
                                                ))
                            Spacer()
                            Image(systemName: "chart.xyaxis.line")
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(powerColor)
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    

                    Button(action: {
                        navigationCoordinator.goToView(targetView: NavigationTarget.ChartViewCadence)
                    })
                    {
                        HStack{
                            SummaryMetricView(title: "Average Cadence",
                                              value: activityRecord.averageCadence
                                .formatted(.number.precision(.fractionLength(0))))
                            Spacer()
                            Image(systemName: "chart.xyaxis.line")
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(cadenceColor)
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    
                    SummaryMetricView(title: "Energy",
                                      value: Measurement(value: activityRecord.activeEnergy,
                                                         unit: UnitEnergy.kilocalories).formatted(.measurement(
                                                            width: .abbreviated,
                                                            usage: .workout)))
                }
                .foregroundStyle(.foreground)

            }



        }
        .onAppear( perform: { activityRecord.getMapSnapshot(datacache: dataCache) })

        .navigationDestination(for: NavigationTarget.self) { pathValue in

            if pathValue == .MapRouteView {

                MapRouteView(activityRecord: activityRecord,
                             dataCache: dataCache)
            }
            if pathValue == .ChartViewAscent {
                
                ChartView(activityRecord: activityRecord,
                          dataCache: dataCache,
                          chartId: "Ascent")
            }
            else if pathValue == .ChartViewHR {
                ChartView(activityRecord: activityRecord,
                          dataCache: dataCache,
                          chartId: "Heart Rate")
            }
            else if pathValue == .ChartViewPower {
                ChartView(activityRecord: activityRecord,
                          dataCache: dataCache,
                          chartId: "Power")
            }
            else if pathValue == .ChartViewCadence {
                ChartView(activityRecord: activityRecord,
                          dataCache: dataCache,
                          chartId: "Cadence")
            }
            
        }

    }

        
}



struct ActivityDetailView_Previews: PreviewProvider {
    
    static var navigationCoordinator = NavigationCoordinator()
    static var settingsManager = SettingsManager()
    static var record = ActivityRecord(settingsManager: settingsManager)
    static var dataCache = DataCache(settingsManager: settingsManager)
    
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
