//
//  SwiftUIView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 03/11/2024.
//

import SwiftUI
import HealthKit



struct ActivityDetailView: View {
    
    @ObservedObject var activityRecord: ActivityRecord
    @ObservedObject var dataCache: DataCache
    
    @State private var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                GroupBox(label: ActivityHeaderView(activityRecord: activityRecord))
                {

                    NavigationLink(destination: MapRouteView(activityRecord: activityRecord,
                                                             dataCache: dataCache)) {
                        Spacer()
                        Image(uiImage: activityRecord.mapSnapshotImage ?? UIImage(systemName: "map")!.withTintColor(.blue))
                            .resizable()
//                            .aspectRatio(contentMode: .fill)
                            .scaledToFill()
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
                    .foregroundColor(.blue)
                )
                {
                    VStack {

                        SummaryMetricView(title: "Average Speed",
                                          value: speedFormatter(speed: activityRecord.averageSpeed))
                        
                        SummaryMetricView(title: "Distance",
                                          value: distanceFormatter(distance: activityRecord.distanceMeters))
                        

                        NavigationLink(destination: ChartView(activityRecord: activityRecord,
                                                              dataCache: dataCache,
                                                              chartId: "Ascent")) {
                            HStack{
                                SummaryMetricView(title: "Ascent / Descent",
                                                  value: (distanceFormatter(distance: activityRecord.totalAscent ?? 0, forceMeters: true)) + " / " +
                                                  (distanceFormatter(distance: activityRecord.totalDescent ?? 0, forceMeters: true)))
                                Spacer()
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(.blue)
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
                    .foregroundColor(.red)
                )
                {
                    VStack {
                        NavigationLink(destination: ChartView(activityRecord: activityRecord,
                                                              dataCache: dataCache,
                                                              chartId: "Heart Rate")) {
                            HStack{
                                SummaryMetricView(title: "Average",
                                                  value: activityRecord.averageHeartRate
                                    .formatted(.number.precision(.fractionLength(0))) + " bpm")
                                Spacer()
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(.red)
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
                    .foregroundColor(.orange)
                )
                {
                    VStack {

                        NavigationLink(destination: ChartView(activityRecord: activityRecord,
                                                              dataCache: dataCache,
                                                              chartId: "Power")) {
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
                                    .foregroundStyle(.orange)
                            }

                        }
                        .buttonStyle(BorderlessButtonStyle())

                        NavigationLink(destination: ChartView(activityRecord: activityRecord,
                                                              dataCache: dataCache,
                                                              chartId: "Cadence")) {
                            HStack{
                                SummaryMetricView(title: "Average Cadence",
                                                  value: activityRecord.averageCadence
                                    .formatted(.number.precision(.fractionLength(0))))
                                Spacer()
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .foregroundStyle(.orange)
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

        }
        .onAppear( perform: { activityRecord.getMapSnapshot(datacache: dataCache) })

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
