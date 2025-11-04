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
    
    struct HRbySector: Identifiable {
        let id = UUID()
        let sector: String
        let startTime: Int
        let value: Int
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
    
    func viewOnStrava(recordId: Int) {

        if let url = URL(string: "strava://activities/" + String(recordId)) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:])
            }
        }

    }
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
    
    func trainingLoadByRange(_ activityRecord: ActivityRecord) -> [DonutChartDataPoint] {
        
        var rangeValues: [Double] = []
        
        if trainingLoadEstimated(activityRecord) {
            rangeValues.append(activityRecord.TSSEstimatebyHRZone[0] + activityRecord.TSSEstimatebyHRZone[1])
            rangeValues.append(activityRecord.TSSEstimatebyHRZone[2] + activityRecord.TSSEstimatebyHRZone[3])
            rangeValues.append(activityRecord.TSSEstimatebyHRZone[4])
        }
        else {
            rangeValues.append(activityRecord.TSSbyPowerZone[0] + activityRecord.TSSbyPowerZone[1])
            rangeValues.append(activityRecord.TSSbyPowerZone[2] + activityRecord.TSSbyPowerZone[3])
            rangeValues.append(activityRecord.TSSbyPowerZone[4] + activityRecord.TSSbyPowerZone[5])
        }

        return [DonutChartDataPoint(name: "Low Aerobic",
                                    color: .blue,
                                    value: rangeValues[0],
                                    formattedValue: String(format: "%.1f", rangeValues[0])),
                DonutChartDataPoint(name: "High Aerobic",
                                    color: .green,
                                    value: rangeValues[1],
                                    formattedValue: String(format: "%.1f", rangeValues[1])),
                DonutChartDataPoint(name: "Anaerobic",
                                    color: .orange,
                                    value: rangeValues[2],
                                    formattedValue: String(format: "%.1f", rangeValues[2]))]

    }
    
    func movingTimeByRange(_ activityRecord: ActivityRecord) -> [DonutChartDataPoint] {
    
        var rangeValues: [Double] = []
        
        if activityRecord.hasHRData {
            rangeValues.append(activityRecord.movingTimebyHRZone[0] + activityRecord.movingTimebyHRZone[1])
            rangeValues.append(activityRecord.movingTimebyHRZone[2] + activityRecord.movingTimebyHRZone[3])
            rangeValues.append(activityRecord.movingTimebyHRZone[4])
        }
        else if activityRecord.hasPowerData {
            rangeValues.append(activityRecord.movingTimebyPowerZone[0] + activityRecord.movingTimebyPowerZone[1])
            rangeValues.append(activityRecord.movingTimebyPowerZone[2] + activityRecord.movingTimebyPowerZone[3])
            rangeValues.append(activityRecord.movingTimebyPowerZone[4] + activityRecord.movingTimebyPowerZone[5])
        } else {
            return []
        }
        
        return [DonutChartDataPoint(name: "Low Aerobic",
                                    color: .blue,
                                    value: rangeValues[0],
                                    formattedValue: elapsedTimeFormatter(elapsedSeconds: rangeValues[0], minimizeLength: true)),
                DonutChartDataPoint(name: "High Aerobic",
                                    color: .green,
                                    value: rangeValues[1],
                                    formattedValue: elapsedTimeFormatter(elapsedSeconds: rangeValues[1], minimizeLength: true)),
                DonutChartDataPoint(name: "Anaerobic",
                                    color: .orange,
                                    value: rangeValues[2],
                                    formattedValue: elapsedTimeFormatter(elapsedSeconds: rangeValues[2], minimizeLength: true))]
        
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
            GroupBox(label:
                HStack {
                    ActivityHeaderView(activityRecord: activityRecord)
                    Spacer()
                
                    LinkToStravaView(activityRecord: activityRecord)
                
                    VStack {
                        let fileLink: csvExportFile = activityRecord.asCSVExportFile(dataCache: dataCache)

                        ShareLink(item: fileLink,
                                  subject: Text(activityRecord.name),
                                  preview: SharePreview("Share Activity Data"))
                        {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 10))
                        Spacer()
                    }
                
                }
            )
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
                    .foregroundColor(TSSColor)
                    
                    Divider()
                }
                )
                {
                    VStack
                    {
                        if trainingLoadEstimated(activityRecord) {
                            Text("Estimated from Heart Rate").bold()
                        }
                        
                        let chartData = trainingLoadByRange(activityRecord)
                        DonutChartView(chartData: chartData,
                                       totalName: "Total Load",
                                       totalValue: String(format: "%.1f", totalTrainingLoad(activityRecord)))

                    }
                }
            }

            
            if activityRecord.hasLocationData {
                GroupBox(label:
                    VStack {
                    HStack {
                        Image(systemName: speedIcon)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                        Text("Speed / Distance")
                        Spacer()
                        
                        Button(action: {
                            navigationCoordinator.goToView(targetView: NavigationTarget.ChartViewAscent)
                        })
                        {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(distanceColor)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    Divider()
                        
                    }
                    .foregroundColor(distanceColor)
                )
                {
                    VStack {
                        Image(uiImage: activityRecord.altitudeImage ?? UIImage(systemName: "photo")!)
                            .resizable()
                            .scaledToFit()
                            .padding(.horizontal)
                            .background(Color.gray.opacity(0))

                        VStack {

                            Spacer()
                            
                            SummaryMetricView(title: "Distance",
                                              value: distanceFormatter(distance: activityRecord.distanceMeters),
                                              metric2title: "Ascent / Descent",
                                              metric2value: (distanceFormatter(distance: activityRecord.totalAscent ?? 0, forceMeters: true)) + " / " +
                                              (distanceFormatter(distance: activityRecord.totalDescent ?? 0, forceMeters: true)))
                            
                            SummaryMetricView(title: "Average Speed",
                                              value: speedFormatter(speed: activityRecord.averageSpeed),
                                              metric2title: "Maximum Speed",
                                              metric2value: speedFormatter(speed: activityRecord.maxSpeed))
                                 
                        }
                        .foregroundStyle(.foreground)
                    }

                }
                
            }
            
            
            GroupBox(label:
                        VStack {
                HStack {
                    Image(systemName: "stopwatch")
                        .font(.title2)
                        .frame(width: 40, height: 40)
                    if activityRecord.hasHRData {
                        Text("Activity Time - by Heart Rate Zone")
                    } else if activityRecord.hasPowerData {
                        Text("Activity Time - by Power Zone")
                    } else {
                        Text("Activity Time")
                    }
                    
                    Spacer()

                }
                .foregroundColor(.green)
                
                Divider()
            }
            )
            {
                VStack
                {
                    let chartData = movingTimeByRange(activityRecord)
                    if chartData.count > 0 {
                        DonutChartView(chartData: chartData,
                                       totalName: "Moving Time",
                                       totalValue: elapsedTimeFormatter(elapsedSeconds: activityRecord.movingTime, minimizeLength: true))
                    }
                    else {
                        SummaryMetricView(title: "Moving Time",
                                          value: elapsedTimeFormatter(elapsedSeconds: activityRecord.movingTime, minimizeLength: false))
                    }


                    SummaryMetricView(title: "Elapsed Time",
                                      value: durationFormatter.string(from: activityRecord.elapsedTime) ?? "",
                                      metric2title: "Paused Time",
                                      metric2value: durationFormatter.string(from: activityRecord.pausedTime) ?? "")
                    
                }
            }


            if activityRecord.hasHRData {
                GroupBox(label:
                    VStack {
                    HStack {
                        Image(systemName: heartRateIcon)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                        Text("Heart Rate")
                        Spacer()
 
                        
                        Button(action: {
                            navigationCoordinator.goToView(targetView: NavigationTarget.ChartViewHR)
                        })
                        {

                            Image(systemName: "chart.xyaxis.line")
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(heartRateColor)

                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                    }
                    
                    Divider()
                        
                    }
                    .foregroundColor(heartRateColor)
                )
                {
                    VStack {
                        
                        SegmentBarView(segmentValues: activityRecord.HRSegmentAverages,
                                       segmentSize: activityRecord.averageSegmentSize ?? 60,
                                       horizontalLineVal: Int(activityRecord.averageHeartRate),
                                       colourScheme: heartRateColor)

                        SummaryMetricView(title: "Average",
                                          value: heartRateFormatter(heartRate: Double(activityRecord.averageHeartRate)) + " bpm",
                                          metric2title: "Maximum",
                                          metric2value: heartRateFormatter(heartRate: Double(activityRecord.maxHeartRate)) + " bpm")
                        
                        if (activityRecord.hiHRLimit != nil) || (activityRecord.loHRLimit != nil) {
                            SummaryMetricView(title: activityRecord.hiHRLimit == nil ? "" : "Over Limit (\(activityRecord.hiHRLimit!))",
                                              value: durationFormatter.string(from: activityRecord.timeOverHiAlarm) ?? "",
                                              metric2title: activityRecord.loHRLimit == nil ? ""   : "Under Limit (\(activityRecord.loHRLimit!))",
                                              metric2value: durationFormatter.string(from: activityRecord.timeUnderLoAlarm) ?? "")
                        }
                        
                    }
                    .foregroundStyle(.foreground)
                }

            }

            if activityRecord.hasPowerData {
                GroupBox(label:
                    VStack {
                    HStack {
                        Image(systemName: powerIcon)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                        Text("Power")
                        
                        Spacer()
                        
                        Button(action: {
                            navigationCoordinator.goToView(targetView: NavigationTarget.ChartViewPower)
                        })
                        {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(powerColor)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    Divider()
                        
                    }
                    .foregroundColor(powerColor)
                )
                {
                    VStack {

                        SegmentBarView(segmentValues: activityRecord.powerSegmentAverages,
                                       segmentSize: activityRecord.averageSegmentSize ?? 60,
                                       horizontalLineVal: Int(activityRecord.averagePower),
                                       colourScheme: powerColor)
                        

                        
                        SummaryMetricView(title: "Average",
                                          value: powerFormatter(watts: Double(activityRecord.averagePower)),
                                          metric2title: "Maximum",
                                          metric2value: powerFormatter(watts: Double(activityRecord.maxPower)))
                        
                        SummaryMetricView(title: "Energy",
                                          value: energyFormatter(energy: activityRecord.activeEnergy))
                    }
                    .foregroundStyle(.foreground)

                }

            }

            
            if activityRecord.hasPowerData {
                GroupBox(label:
                    VStack {
                    HStack {
                        Image(systemName: cadenceIcon)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                        Text("Cadence")
                        
                        Spacer()
                        
                        Button(action: {
                            navigationCoordinator.goToView(targetView: NavigationTarget.ChartViewCadence)
                        })
                        {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .foregroundStyle(cadenceColor)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    
                    Divider()
                        
                    }
                    .foregroundColor(cadenceColor)
                )
                {
                    VStack {

                        SegmentBarView(segmentValues: activityRecord.cadenceSegmentAverages,
                                       segmentSize: activityRecord.averageSegmentSize ?? 60,
                                       horizontalLineVal: Int(activityRecord.averageCadence),
                                       colourScheme: cadenceColor)
                        
                        SummaryMetricView(title: "Average",
                                          value: cadenceFormatter(cadence: Double(activityRecord.averageCadence)),
                                          metric2title: "Maximum",
                                          metric2value: cadenceFormatter(cadence: Double(activityRecord.maxCadence)))

                    }
                    .foregroundStyle(.foreground)

                }

            }

            if SettingsManager.shared.offerSaveToStrava() {
                switch activityRecord.stravaSaveStatus {
                case StravaSaveStatus.notSaved.rawValue:
                    Button(action: {
                        activityRecord.saveToStrava()
                    })
                    {
                        HStack {
                            Text("Save to Strava")
                                .font(.title2)
                                .foregroundStyle(Color("StravaColor"))
                            Image("StravaIcon").resizable().frame(width: 30, height: 30)

                        }

                    }
                    .tint(Color.orange)
                    .buttonStyle(.bordered)
                    
                case StravaSaveStatus.saved.rawValue:
                    VStack {
                        Button(action: {
                            if let stravaId = activityRecord.stravaId {
                                viewOnStrava(recordId: stravaId)
                            }
                        })
                        {
                            HStack {
                                Text("View on Strava")
                                    .font(.title2)
                                    .foregroundStyle(Color("StravaColor"))
                                Image("StravaIcon").resizable().frame(width: 30, height: 30)

                            }

                        }
                        .tint(Color.orange)
                        .buttonStyle(.bordered)

                        Button(action: {
                            if let stravaId = activityRecord.stravaId {
                                StravaUpdateActivity(activityRecord: activityRecord,
                                                     completionHandler: { _ in }).execute()
                            }
                        })
                        {
                            HStack {
                                Text("Update on Strava")
                                    .font(.title2)
                                    .foregroundStyle(Color("StravaColor"))
                                Image("StravaIcon").resizable().frame(width: 30, height: 30)

                            }

                        }
                        .tint(Color.orange)
                        .buttonStyle(.bordered)
                        
                    }

                    
                case StravaSaveStatus.toSave.rawValue:
                    Text("To be saved...")
                        .foregroundStyle(Color("StravaColor"))

                case StravaSaveStatus.saving.rawValue:
                    HStack {
                        Text("Saving...")
                            .foregroundStyle(Color("StravaColor"))
                        ProgressView()
                    }

                    
                default:
                    Text("")
                }
            }

        }
        .onAppear( perform: {

            ActivityRecordSnapshotImage(activityRecord: activityRecord,
                                        dataCache: dataCache)
            .get(image: &activityRecord.mapSnapshotImage,
                 url: &activityRecord.mapSnapshotURL,
                 asset: activityRecord.mapSnapshotAsset)
            
            ActivityRecordAltitudeImage(activityRecord: activityRecord,
                                        dataCache: dataCache)
            .get(image: &activityRecord.altitudeImage,
                 url: &activityRecord.altitudeImageURL,
                 asset: activityRecord.altitudeImageAsset)
        })
        
        .refreshable {
            if activityRecord.stravaId != nil {
                if SettingsManager.shared.fetchFromStrava() {
                    activityRecord.fetchUpdateFromStrava(dataCache: dataCache)
                }
                
            }
        }

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
