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
        VStack {

            Text(viewTitleText)
            
//            SummaryMetricsSubView(profileData: profileData)

            Form {

                HStack {
                    Text("Total Time")
                        .foregroundColor(Color.yellow)
                    Spacer().frame(maxWidth: .infinity)
                    Text(durationFormatter.string(from: metrics.duration) ?? "")
                        .foregroundStyle(.yellow)
                }
                HStack {
                    Image(systemName: "heart.fill").foregroundColor(Color.red)
                    Text("Ave.").foregroundColor(Color.yellow)
                    Spacer().frame(maxWidth: .infinity)
                    Text(metrics.averageHeartRate
                        .formatted(.number.precision(.fractionLength(0))) + " bpm")
                }
                HStack {
                    Text("Recovery").foregroundColor(Color.yellow)
                    
                    Spacer().frame(maxWidth: .infinity)
                    Text(metrics.heartRateRecovery
                        .formatted(.number.precision(.fractionLength(0))) )
                }
                
                HStack {
                    
                    Text("Energy").foregroundColor(Color.yellow)
                    
                    Spacer().frame(maxWidth: .infinity)
                    
                    Text(Measurement(value: metrics.activeEnergy,
                                     unit: UnitEnergy.kilocalories).formatted(.measurement(
                                        width: .abbreviated,
                                        usage: .workout
                                        //                                        numberFormat: .numeric(precision: .fractionLength(0))
                                     ))
                    )
                }
                HStack {
                    
                    Text("Dist.").foregroundColor(Color.yellow)
                    Spacer().frame(maxWidth: .infinity)
                    Text(distanceFormatter(distance: metrics.distance)
                        )
                }

                if displayDone {
                    Button(action: SaveWorkout) {
                        Text("Done").padding([.leading, .trailing], 60)
                    }

                }
                
            }

        }
    }

    func SaveWorkout() {
//        profileData.summaryMetrics.duration = profileData.workout?.duration ?? 0.0
        
        profileData.summaryMetrics.put(tag: "LastSession")
        profileData.lastSummaryMetrics.get(tag: "LastSession")
        profileData.summaryMetrics.reset()
        
        profileData.appState = .initial
    }
}

struct SummaryMetricsView_Previews: PreviewProvider {

    static var profileData = ProfileData()
    static var summaryMetrics = SummaryMetrics(
        duration: 0,
        averageHeartRate: 0,
        heartRateRecovery: 0,
        activeEnergy: 0,
        distance: 0
        )

    static var previews: some View {
        SummaryMetricsView(profileData: profileData,
                           viewTitleText: "Hello World",
                           displayDone: true,
                           metrics: summaryMetrics)
    }
}
