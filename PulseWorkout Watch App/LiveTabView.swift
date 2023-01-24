//
//  LiveTabView.swift
//  PulsePace Watch App
//
//  Created by Robin Murray on 18/12/2022.
//

//import Foundation
import SwiftUI
import WatchKit

enum LiveScreenTab {
    case stop, liveMetrics, nowPlaying
}

struct LiveTabView: View {
    
    @ObservedObject var profileData: ProfileData

//    @State private var selection: LiveScreenTab = .liveMetrics
    
    init(profileData: ProfileData) {
        self.profileData = profileData
    }
    
    var body: some View {
        TabView(selection: $profileData.liveTabSelection) {

            StopView(profileData: profileData)
                .tag(LiveScreenTab.stop)
            
            LiveMetricsView(profileData: profileData)
                .tag(LiveScreenTab.liveMetrics)

            
            NowPlayingView()
                .tag(LiveScreenTab.nowPlaying)

        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))

    }
    
}
    




struct LIveTabView_Previews: PreviewProvider {
    
    static var profileData = ProfileData()

    static var previews: some View {
        LiveTabView(profileData: profileData)
    }
}

