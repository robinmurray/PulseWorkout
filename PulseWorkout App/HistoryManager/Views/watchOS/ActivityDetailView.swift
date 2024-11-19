//
//  ActivityDetailView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 30/06/2023.
//

import SwiftUI
import HealthKit



struct GraphButtonView: View {
    
    @State var buttonColor: Color
    @State var activityRecord: ActivityRecord
    @ObservedObject var dataCache: DataCache
    
    var body: some View {
        
        VStack {
            Spacer()

            NavigationStack {
                NavigationLink(destination: ChartView(activityRecord: activityRecord,
                                                     dataCache: dataCache)) {
                    
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundColor(buttonColor)
                        .font(.title2)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(BorderlessButtonStyle())
                
                NavigationLink(destination: ChartView(activityRecord: activityRecord,
                                                      dataCache: dataCache)) {
                    
                    Image(systemName: "chart.bar.xaxis")
                        .foregroundColor(buttonColor)
                        .font(.title2)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(BorderlessButtonStyle())
            
                NavigationLink(destination: MapRouteView(activityRecord: activityRecord,
                                                         dataCache: dataCache)) {
                    
                    Image(systemName: "map.circle")
                        .foregroundColor(buttonColor)
                        .font(.title2)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }

    }
}

struct ActivityDetailView: View {
    
    @State var activityRecord: ActivityRecord
    @ObservedObject var dataCache: DataCache
    
    @State private var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    
    var body: some View {
        
        TabView {
            HStack {
                VStack(alignment: .leading) {
                    
                    HStack {
                        Image(systemName:"stopwatch")
                            .foregroundColor(Color.green)
                        Spacer()
                        Text(durationFormatter.string(from: activityRecord.movingTime) ?? "")
                            .foregroundStyle(.green)
                            .font(.system(.title3, design: .rounded).lowercaseSmallCaps())
                    }
                    Divider()
                    
                    HStack {
                        Image(systemName: distanceIcon)
                            .foregroundColor(Color.blue)
                        Spacer()
                        Text(distanceFormatter(distance: activityRecord.distanceMeters))
                            .foregroundStyle(.blue)
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
                            .foregroundColor(Color.red)
                        Spacer()
                        Text(activityRecord.averageHeartRate
                            .formatted(.number.precision(.fractionLength(0))) + " bpm")
                        .foregroundStyle(.red)
                        .font(.system(.title3, design: .rounded).lowercaseSmallCaps())
                    }
                    Divider()
                    
                }
            
                GraphButtonView(buttonColor: .blue,
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
                
                GraphButtonView(buttonColor: .green,
                                activityRecord: activityRecord,
                                dataCache: dataCache)
                
            }
            .containerBackground(.green.gradient, for: .tabView)
            
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
                
                GraphButtonView(buttonColor: .blue,
                                activityRecord: activityRecord,
                                dataCache: dataCache)
                
            }
            .navigationTitle("Distance")
            .containerBackground(.blue.gradient, for: .tabView)
            
            HStack {
                VStack {
                    SummaryMetricView(title: "Average",
                                      value: activityRecord.averageHeartRate
                        .formatted(.number.precision(.fractionLength(0))) + " bpm")
                    .foregroundStyle(.yellow)
                    
                    SummaryMetricView(title: activityRecord.hiHRLimit == nil ? "Time Over High Limit" : "Time Over High Limit (\(activityRecord.hiHRLimit!))",
                                      value: durationFormatter.string(from: activityRecord.timeOverHiAlarm) ?? "0")
                    .foregroundStyle(.yellow)
                    
                    SummaryMetricView(title: activityRecord.loHRLimit == nil ? "Time Under Low Limit"   : "Time Under Low Limit (\(activityRecord.loHRLimit!))",
                                      value: durationFormatter.string(from: activityRecord.timeUnderLoAlarm) ?? "0")
                    .foregroundStyle(.yellow)
                    
                }
                
                GraphButtonView(buttonColor: .red,
                                activityRecord: activityRecord,
                                dataCache: dataCache)
                
            }
            .navigationTitle("Heart Rate")
            .containerBackground(.red.gradient, for: .tabView)
            
            HStack {
                VStack {
                    
                    SummaryMetricView(title: "Average Power",
                                      value: Measurement(value: Double(activityRecord.averagePower),
                                                         unit: UnitPower.watts)
                                        .formatted(.measurement(width: .abbreviated,
                                                                usage: .asProvided)
                                        ))
                    .foregroundStyle(.yellow)
                    
                    SummaryMetricView(title: "Average Cadence",
                                      value: activityRecord.averageCadence
                        .formatted(.number.precision(.fractionLength(0))))
                    .foregroundStyle(.yellow)
                    
                    SummaryMetricView(title: "Energy",
                                      value: Measurement(value: activityRecord.activeEnergy,
                                                         unit: UnitEnergy.kilocalories).formatted(.measurement(
                                                            width: .abbreviated,
                                                            usage: .workout)))
                    .foregroundStyle(.yellow)
                    
                }
                
                GraphButtonView(buttonColor: .orange,
                                activityRecord: activityRecord,
                                dataCache: dataCache)
                
            }
            .navigationTitle("Power")
            .containerBackground(.orange.gradient, for: .tabView)
            
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
        
    }

}




struct ActivityDetailView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var record = ActivityRecord(settingsManager: settingsManager)
    static var dataCache = DataCache(settingsManager: settingsManager)
    
    static var previews: some View {
        if #available(watchOS 10.0, *) {
            ActivityDetailView(activityRecord: record, dataCache: dataCache)
        } else {
            // Fallback on earlier versions
        }
    }
}
