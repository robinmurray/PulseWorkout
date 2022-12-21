//
//  SummaryView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import Foundation


import SwiftUI

struct SummaryView: View {

    @ObservedObject var profileData: ProfileData
    
    
    init(profileData: ProfileData) {
        self.profileData = profileData
    }


    @State private var selection: Tab = .summary
    
    var body: some View {
        TabView(selection: $selection) {
            Text("Summary Stats View").tag(Tab.summary)
            
            Text("Now playing").tag(Tab.nowPlaying)
            
            HelpView()
                .tag(Tab.help)
            
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
    }
}

struct SummaryView_Previews: PreviewProvider {
    static var profileData = ProfileData()

    static var previews: some View {
        SummaryView(profileData: profileData)
    }
}

