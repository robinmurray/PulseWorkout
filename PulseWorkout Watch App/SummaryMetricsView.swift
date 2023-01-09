//
//  SummaryMetricsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import SwiftUI

struct SummaryMetricsView: View {
    
    @ObservedObject var profileData: ProfileData
    
    
    init(profileData: ProfileData) {
        self.profileData = profileData
    }


    var body: some View {
        VStack {

            Text("Workout Summary")
            Form {
                HStack {
                    Image(systemName: "heart.fill").foregroundColor(Color.red)
                    Text("Ave.").foregroundColor(Color.yellow)
                    Spacer().frame(maxWidth: .infinity)
                    Text(profileData.averageHeartRate
                        .formatted(.number.precision(.fractionLength(0))) + " bpm")
                }
                HStack {
                    Text("Recovery").foregroundColor(Color.yellow)
                    
                    Spacer().frame(maxWidth: .infinity)
                    Text(profileData.heartRateRecovery
                        .formatted(.number.precision(.fractionLength(0))) )
                }
                
                HStack {
                    
                    Text("Energy").foregroundColor(Color.yellow)
                    
                    Spacer().frame(maxWidth: .infinity)
                    
                    Text(Measurement(value: profileData.activeEnergy,
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
                    Text(Measurement(value: profileData.distance,
                                     unit: UnitLength.kilometers)
                        .formatted(.measurement(width: .abbreviated,
                                                usage: .asProvided
                                               )
                        )
                    )
                }
                
                Button(action: {
                    profileData.appState = .initial
                }) {
                    Text("Done").padding([.leading, .trailing], 60)
                }
                
            }

        }
    }

}

struct SummaryMetricsView_Previews: PreviewProvider {

    static var profileData = ProfileData()

    static var previews: some View {
        SummaryMetricsView(profileData: profileData)
    }
}
