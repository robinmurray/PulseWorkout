//
//  LiveTabView.swift
//  PulsePace Watch App
//
//  Created by Robin Murray on 18/12/2022.
//

//import Foundation
import SwiftUI
import WatchKit

struct LiveTabView: View {
    
    enum Tab {
        case stop, liveMetrics, nowPlaying
    }

    @ObservedObject var profileData: ProfileData

    @State private var selection: Tab = .liveMetrics
    
    init(profileData: ProfileData) {
        self.profileData = profileData
    }
    
    var body: some View {
        TabView(selection: $selection) {

            StopView(profileData: profileData)
                .tag(Tab.stop)
            
            LiveMetricsView(profileData: profileData)
                .tag(Tab.liveMetrics)
            
            NowPlayingView().tag(Tab.nowPlaying)

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

