//
//  SwiftUIView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 03/11/2024.
//

import SwiftUI
import HealthKit
import Charts


struct ActivityDetailView: View {
    
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @ObservedObject var activityRecord: ActivityRecord
    @ObservedObject var dataCache: DataCache
    
    struct TrainingLoadByRange : Identifiable {
        let id = UUID()
        let range: String
        let value: Double
    }
    
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
    
    func hasTrainingLoad(_ activityRecord: ActivityRecord) -> Bool {
        
        if (((activityRecord.TSS ?? 0) > 0) &&
            (activityRecord.TSSbyPowerZone.count == 6)) ||
            (((activityRecord.estimatedTSSbyHR ?? 0) > 0) &&
             (activityRecord.TSSEstimatebyHRZone.count == 5)) {
            
            return true
        }
        
        return false
    }
    
    func trainingLoadEstimated(_ activityRecord: ActivityRecord) -> Bool {
        
        if ((activityRecord.TSS ?? 0) > 0) {
            return false
        }
        return true
    }
    
    func trainingLoadByRange(_ activityRecord: ActivityRecord) -> [TrainingLoadByRange] {
        
        if trainingLoadEstimated(activityRecord) {
            return [TrainingLoadByRange(range: "Low Aerobic",
                                        value: activityRecord.TSSEstimatebyHRZone[0] + activityRecord.TSSEstimatebyHRZone[1]),
                    TrainingLoadByRange(range: "High Aerobic",
                                        value: activityRecord.TSSEstimatebyHRZone[2] + activityRecord.TSSEstimatebyHRZone[3]),
                    TrainingLoadByRange(range: "Anaerobic",
                                        value: activityRecord.TSSEstimatebyHRZone[4])]
        }
        else {
            return [TrainingLoadByRange(range: "Low Aerobic",
                                        value: activityRecord.TSSbyPowerZone[0] + activityRecord.TSSbyPowerZone[1]),
                    TrainingLoadByRange(range: "High Aerobic",
                                        value: activityRecord.TSSbyPowerZone[2] + activityRecord.TSSbyPowerZone[3]),
                    TrainingLoadByRange(range: "Anaerobic",
                                        value: activityRecord.TSSbyPowerZone[4] + activityRecord.TSSbyPowerZone[5])]
        }
    }
    
    func totalTrainingLoad(_ activityRecord: ActivityRecord) -> Double {
        
        if trainingLoadEstimated(activityRecord) {
            return activityRecord.estimatedTSSbyHR ?? 0
        }
        else {
            return activityRecord.TSS ?? 0
        }
    }
    
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

            if hasTrainingLoad(activityRecord) {
                
                GroupBox(label:
                            VStack {
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional.circle")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                        Text("Training Load")
                        Spacer()

                    }
                    .foregroundColor(.purple)
                    
                    Divider()
                }
                )
                {
                    VStack
                    {
                        if trainingLoadEstimated(activityRecord) {
                            Text("Estimated from Heart Rate").bold()
                        }
                        
                        let trainingLoads = trainingLoadByRange(activityRecord)
                     
                        ZStack {

                            // The donut chart
                            Chart(trainingLoads) { trainingLoad in
                                SectorMark(
                                    angle: .value(
                                        Text(verbatim: trainingLoad.range),
                                        trainingLoad.value
                                    ),
                                    innerRadius: .ratio(0.618),
                                    angularInset: 8
                                )
                                .foregroundStyle(
                                    by: .value(
                                        "Name",
                                        trainingLoad.range
                                    )
                                )
                                .cornerRadius(6)
                                .annotation(position: .overlay) {
                                    if trainingLoad.value > 0 {
                                        Text(String(format: "%.1f", trainingLoad.value)).bold()
                                    }
                                    
                                }
                            }
                            .frame(width: 300, height: 300)
                            
                            // The text in the centre
                            VStack(alignment:.center) {
                                Text("Total Load").bold()
                                Text(String(format: "%.1f", totalTrainingLoad(activityRecord))).bold()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            
                                
                        }

                    }
                }
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
                                              value: heartRateFormatter(heartRate: Double(activityRecord.averageHeartRate)) + " bpm")
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
                                              value: powerFormatter(watts: Double(activityRecord.averagePower))
                                                )
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
                                              value: cadenceFormatter(cadence: Double(activityRecord.averageCadence))
                                                )
                            Spacer()
                            Image(systemName: "chart.xyaxis.line")
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(cadenceColor)
                        }
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    
                    SummaryMetricView(title: "Energy",
                                      value: energyFormatter(energy: activityRecord.activeEnergy))
                }
                .foregroundStyle(.foreground)

            }



        }
        .onAppear( perform: { activityRecord.getMapSnapshot(dataCache: dataCache) })

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
