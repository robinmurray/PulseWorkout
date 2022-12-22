//
//  InitialView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import Foundation
import SwiftUI

struct InitialView: View {

    @ObservedObject var profileData: ProfileData
    
    
    init(profileData: ProfileData) {
        self.profileData = profileData
    }


    @State private var selection: Tab = .start
    
    var body: some View {
        TabView(selection: $selection) {

            Text("Workout type").tag(Tab.workoutType)
            
            StartView(profileData: profileData)
                .tag(Tab.start)

            ProfileView(profileData: profileData)
                .tag(Tab.profile)
            
            Text("Now playing").tag(Tab.nowPlaying)
            
            HelpView()
                .tag(Tab.help)
            
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
    }
}

struct InitialView_Previews: PreviewProvider {
    static var profileData = ProfileData()

    static var previews: some View {
        InitialView(profileData: profileData)
    }
}
