//
//  StartTabView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import Foundation
import SwiftUI
import WatchKit

struct StartTabView: View {

    enum Tab {
        case workoutType, start, profile, nowPlaying, help
    }

    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var profileData: ProfileData
    @State private var selection: Tab = .start
    
    
    init(profileData: ProfileData) {
        self.profileData = profileData
    }

    var body: some View {
        TabView(selection: $selection) {

            WorkoutSelectionView(profileData: profileData).tag(Tab.workoutType)
            
            StartView(profileData: profileData)
                .tag(Tab.start)

            ProfileView(profileData: profileData)
                .tag(Tab.profile)
            
            NowPlayingView().tag(Tab.nowPlaying)
            
            HelpView()
                .tag(Tab.help)
            
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
        .onAppear { workoutManager.requestAuthorization() }
    }
}

struct StartTabView_Previews: PreviewProvider {
    static var profileData = ProfileData()

    static var previews: some View {
        StartTabView(profileData: profileData)
    }
}
