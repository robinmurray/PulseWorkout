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

            Text("Summary Metrics")

            Spacer().frame(maxWidth: .infinity)

            Button(action: {
                profileData.appState = .initial
            }) {
            Text("Done")
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
