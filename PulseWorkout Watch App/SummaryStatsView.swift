//
//  SummaryStatsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import SwiftUI

struct SummaryStatsView: View {
    
    @ObservedObject var profileData: ProfileData
    
    
    init(profileData: ProfileData) {
        self.profileData = profileData
    }


    var body: some View {
        VStack {

            Text("Summary Stats View").tag(Tab.summary)

            Spacer().frame(maxWidth: .infinity)

            Button(action: {
                profileData.appState = .initial
            }) {
            Text("Dismiss")
            }
            
        }
    }

}

struct SummaryStatsView_Previews: PreviewProvider {

    static var profileData = ProfileData()

    static var previews: some View {
        SummaryStatsView(profileData: profileData)
    }
}
