//
//  SummaryMetricsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import SwiftUI

struct SummaryMetricsView: View {
    
    @ObservedObject var profileData: ProfileData
    var viewTitleText: String
    var displayDone: Bool
    var metrics: SummaryMetrics
    
    @State private var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    init(profileData: ProfileData, viewTitleText: String, displayDone: Bool, metrics: SummaryMetrics) {
        self.profileData = profileData
        self.viewTitleText = viewTitleText
        self.displayDone = displayDone
        self.metrics = metrics
    }


    var body: some View {
        
        ScrollView {
            VStack(alignment: .leading) {
 //               Text(viewTitleText)

                SummaryMetricView(title: "Total Time",
                                  value: durationFormatter.string(from: metrics.duration) ?? "")
                .foregroundStyle(.yellow)

                SummaryMetricView(title: "Time Over High Limit",
                                  value: durationFormatter.string(from: metrics.timeOverHiAlarm) ?? "0")
                .foregroundStyle(.yellow)

                SummaryMetricView(title: "Time Under Low Limit",
                                  value: durationFormatter.string(from: metrics.timeUnderLoAlarm) ?? "0")
                .foregroundStyle(.yellow)
                
                SummaryMetricView(title: "Ave. HR",
                                  value: metrics.averageHeartRate
                    .formatted(.number.precision(.fractionLength(0))) + " bpm")
                .foregroundStyle(.yellow)

                SummaryMetricView(title: "Recovery",
                                  value: metrics.heartRateRecovery
                    .formatted(.number.precision(.fractionLength(0))))
                .foregroundStyle(.yellow)

                SummaryMetricView(title: "Energy",
                                  value: Measurement(value: metrics.activeEnergy,
                                                     unit: UnitEnergy.kilocalories).formatted(.measurement(
                                                        width: .abbreviated,
                                                        usage: .workout)))
                .foregroundStyle(.yellow)

                SummaryMetricView(title: "Dist.",
                                  value: distanceFormatter(distance: metrics.distance))
                .foregroundStyle(.yellow)

                if displayDone {
                    Button(action: SaveWorkout) {
                        Text("Done").padding([.leading, .trailing], 40)
                    }
                }

            }
            .scenePadding()
        }
        .navigationTitle(viewTitleText)
        .navigationBarTitleDisplayMode(.inline)
        
    }

    func SaveWorkout() {
//        profileData.summaryMetrics.duration = profileData.workout?.duration ?? 0.0
        
        profileData.summaryMetrics.put(tag: "LastSession")
        profileData.lastSummaryMetrics.get(tag: "LastSession")
        profileData.summaryMetrics.reset()
        
        profileData.appState = .initial
    }
}


struct SummaryMetricView: View {
    var title: String
    var value: String

    var body: some View {
        Text(title)
            .foregroundStyle(.foreground)
        Text(value)
            .font(.system(.title2, design: .rounded).lowercaseSmallCaps())
        Divider()
    }
}


struct SummaryMetricsView_Previews: PreviewProvider {

    static var profileData = ProfileData()
    static var summaryMetrics = SummaryMetrics(
        duration: 0,
        averageHeartRate: 0,
        heartRateRecovery: 0,
        activeEnergy: 0,
        distance: 0,
        timeOverHiAlarm: 0,
        timeUnderLoAlarm: 0
        )

    static var previews: some View {
        SummaryMetricsView(profileData: profileData,
                           viewTitleText: "Hello World",
                           displayDone: true,
                           metrics: summaryMetrics)
    }
}
