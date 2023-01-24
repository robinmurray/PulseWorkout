//
//  PausedTabView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 23/12/2022.
//

import Foundation
import WatchKit
import SwiftUI

struct PausedTabView: View {

    enum Tab {
        case paused, nowPlaying, help
    }

    @ObservedObject var profileData: ProfileData

    @State private var selection: Tab = .paused
    
    init(profileData: ProfileData) {
        self.profileData = profileData
    }


    var body: some View {
        TabView(selection: $selection) {

            PausedView(profileData: profileData)
                .tag(Tab.paused)
            
            NowPlayingView()
                .tag(Tab.nowPlaying)
            
            HelpView()
                .tag(Tab.help)
            
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
    }
}

struct PausedTabView_Previews: PreviewProvider {
    static var profileData = ProfileData()

    static var previews: some View {
        PausedTabView(profileData: profileData)
    }
}

