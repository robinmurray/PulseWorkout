//
//  ActiveView.swift
//  PulsePace Watch App
//
//  Created by Robin Murray on 18/12/2022.
//

//import Foundation
import SwiftUI


struct ActiveView: View {
    
    @ObservedObject var profileData: ProfileData
    @State private var selection: Tab = .monitor
    

    init(profileData: ProfileData) {
        self.profileData = profileData
    }
    
    var body: some View {
        TabView(selection: $selection) {

            StopView(profileData: profileData).tag(Tab.stop)
            
            LiveMetricsView(profileData: profileData)
                .tag(Tab.monitor)
            
            Text("Now playing").tag(Tab.nowPlaying)
            
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
    }
}
    




struct ActiveView_Previews: PreviewProvider {
    
    static var profileData = ProfileData()

    static var previews: some View {
        ActiveView(profileData: profileData)
    }
}

