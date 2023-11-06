//
//  ActivityDetailView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 30/06/2023.
//

import SwiftUI

func distanceFormatter (distance: Double, forceMeters: Bool = false) -> String {
    var unit = UnitLength.meters
    var displayDistance: Double = distance.rounded()
    if (distance > 1000) && (!forceMeters) {
        unit = UnitLength.kilometers
        displayDistance = distance / 1000
        if displayDistance > 100 {
            displayDistance = (displayDistance * 10).rounded() / 10
        } else if displayDistance > 10 {
            displayDistance = (displayDistance * 100).rounded() / 100
        } else {
            displayDistance = (displayDistance * 10).rounded() / 10
        }

    }
    
    return  Measurement(value: displayDistance,
                       unit: unit)
    .formatted(.measurement(width: .abbreviated,
                            usage: .asProvided
                           )
    )

}

func speedFormatter (speed: Double) -> String {
    // var unit = UnitSpeed.kilometersPerHour
    var speedKPH = speed * 3.6
    
    speedKPH = max(speedKPH, 0)
    
    return String(format: "%.1f", speedKPH) + " k/h"
    
}

struct ActivityHeaderView: View {

    @State var activityRecord: ActivityRecord

    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                Text(activityRecord.name)
                    .foregroundStyle(.yellow)
                Spacer()
            }

            HStack {
                Text(activityRecord.startDateLocal.formatted(
                    Date.FormatStyle(timeZone: TimeZone(abbreviation: TimeZone.current.abbreviation() ?? "")!)
                        .day(.twoDigits)
                        .month(.abbreviated)
                        .hour(.defaultDigits(amPM: .omitted))
                        .minute(.twoDigits)
                        .hour(.conversationalDefaultDigits(amPM: .abbreviated))
                ))
                Spacer()
            }
        }
    }
}

struct ActivityDetailView: View {
    
    @State var activityRecord: ActivityRecord
    
    @State private var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    
    var body: some View {
           
        VStack(alignment: .leading) {
            ActivityHeaderView(activityRecord: activityRecord)
            Divider()


            ScrollView {
                VStack(alignment: .leading) {
                
                    Section("Activity Times") {
                        SummaryMetricView(title: "Elapsed Time",
                                          value: durationFormatter.string(from: activityRecord.elapsedTime) ?? "")
                            .foregroundStyle(.yellow)

                            
                        SummaryMetricView(title: "Moving Time",
                                          value: durationFormatter.string(from: activityRecord.movingTime) ?? "")
                            .foregroundStyle(.yellow)

                            
                        SummaryMetricView(title: "Paused Time",
                                          value: durationFormatter.string(from: activityRecord.pausedTime) ?? "")
                            .foregroundStyle(.yellow)
                    }
                    .foregroundStyle(.blue)
    

                    Section("Activity Distances") {
                        SummaryMetricView(title: "Distance",
                                          value: distanceFormatter(distance: activityRecord.distanceMeters))
                            .foregroundStyle(.yellow)

                        SummaryMetricView(title: "Total Ascent",
                                          value: distanceFormatter(distance: activityRecord.totalAscent ?? 0, forceMeters: true))
                            .foregroundStyle(.yellow)

                        SummaryMetricView(title: "Total Descent",
                                          value: distanceFormatter(distance: activityRecord.totalDescent ?? 0, forceMeters: true))
                            .foregroundStyle(.yellow)
                    }
                    .foregroundStyle(.blue)
                
                    Section("Heart Rates") {
                        SummaryMetricView(title: activityRecord.hiHRLimit == nil ? "Time Over High Limit" : "Time Over High Limit (\(activityRecord.hiHRLimit!))",
                                          value: durationFormatter.string(from: activityRecord.timeOverHiAlarm) ?? "0")
                            .foregroundStyle(.yellow)

                        SummaryMetricView(title: activityRecord.loHRLimit == nil ? "Time Under Low Limit"   : "Time Under Low Limit (\(activityRecord.loHRLimit!))",
                                          value: durationFormatter.string(from: activityRecord.timeUnderLoAlarm) ?? "0")
                            .foregroundStyle(.yellow)

                    }
                    .foregroundStyle(.blue)

                    Section("Averages") {
                        SummaryMetricView(title: "Average Speed",
                                          value: speedFormatter(speed: activityRecord.averageSpeed))
                            .foregroundStyle(.yellow)
               

                        SummaryMetricView(title: "Average HR",
                                          value: activityRecord.averageHeartRate
                                             .formatted(.number.precision(.fractionLength(0))) + " bpm")
                            .foregroundStyle(.yellow)


                        SummaryMetricView(title: "Average Power",
                                          value: Measurement(value: activityRecord.averagePower.rounded(),
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
                    .foregroundStyle(.blue)
                }
            }
        }
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

struct ActivityDetailView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var record = ActivityRecord(settingsManager: settingsManager)
    
    static var previews: some View {
        ActivityDetailView(activityRecord: record)
    }
}
