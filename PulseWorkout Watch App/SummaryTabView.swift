//
//  SummaryTabView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import Foundation
import WatchKit
import SwiftUI

struct SummaryTabView: View {

    enum Tab {
        case summaryMetrics, nowPlaying, help
    }

    @ObservedObject var profileData: ProfileData
    @State private var selection: Tab = .summaryMetrics
    
    init(profileData: ProfileData) {
        self.profileData = profileData
    }


    var body: some View {
        TabView(selection: $selection) {

            SummaryMetricsView(profileData: profileData,
                               viewTitleText: "Summary Metrics",
                               displayDone: true,
                               metrics: profileData.summaryMetrics)
                .tag(Tab.summaryMetrics)
            
            NowPlayingView().tag(Tab.nowPlaying)

            HelpView()
                .tag(Tab.help)
            
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
    }
}

struct SummaryTabView_Previews: PreviewProvider {
    static var profileData = ProfileData()

    static var previews: some View {
        SummaryTabView(profileData: profileData)
    }
}

