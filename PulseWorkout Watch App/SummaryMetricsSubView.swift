//
//  SummaryMetricsSubView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 14/01/2023.
//

import SwiftUI

struct SummaryMetricsSubView: View {
    
    @ObservedObject var profileData: ProfileData
    @State private var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    init(profileData: ProfileData) {
        self.profileData = profileData
    }

    
    var body: some View {
        VStack {

            Form {
                HStack {
                    Text("Total Time")
                        .foregroundColor(Color.yellow)
                    Spacer().frame(maxWidth: .infinity)
                    Text(durationFormatter.string(from: profileData.workout?.duration ?? 0.0) ?? "")
                        .foregroundStyle(.yellow)
                }
                HStack {
                    Image(systemName: "heart.fill").foregroundColor(Color.red)
                    Text("Ave.").foregroundColor(Color.yellow)
                    Spacer().frame(maxWidth: .infinity)
                    Text(profileData.summaryMetrics.averageHeartRate
                        .formatted(.number.precision(.fractionLength(0))) + " bpm")
                }
                HStack {
                    Text("Recovery").foregroundColor(Color.yellow)
                    
                    Spacer().frame(maxWidth: .infinity)
                    Text(profileData.summaryMetrics.heartRateRecovery
                        .formatted(.number.precision(.fractionLength(0))) )
                }
                
                HStack {
                    
                    Text("Energy").foregroundColor(Color.yellow)
                    
                    Spacer().frame(maxWidth: .infinity)
                    
                    Text(Measurement(value: profileData.summaryMetrics.activeEnergy,
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
                    Text(distanceFormatter(distance: profileData.summaryMetrics.distance)
                        )
                }
                                
            }

        }

    }
}

struct SummaryMetricsSubView_Previews: PreviewProvider {

    static var profileData = ProfileData()

    static var previews: some View {
        SummaryMetricsSubView(profileData: profileData)
    }
}
