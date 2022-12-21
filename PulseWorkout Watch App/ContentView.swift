//
//  ContentView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import SwiftUI

enum Tab {
    case start, active, stop, profile, nowPlaying, help, summary
}

enum AppState {
    case initial, active, summary
}

struct ContentView: View {

    @ObservedObject var profileData = ProfileData()
    
    @State private var selection: Tab = .active
    
    var body: some View {
        
        containedView()
    }
        
    func containedView() -> AnyView {
        
        switch profileData.appState {
            
        case .initial:
            return AnyView(InitialView(profileData: profileData))
            
        case .active:
            
            return AnyView(TabView(selection: $selection) {
//                Text("Start View").tag(Tab.start)
                
                ActiveView(profileData: profileData)
                    .tag(Tab.active)
                
//                Text("Stop View").tag(Tab.stop)
                
 //               ProfileView(profileData: profileData)
 //                   .tag(Tab.profile)
                
                Text("Now playing").tag(Tab.nowPlaying)
                
//                HelpView()
//                    .tag(Tab.help)
                
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .automatic)))
            
        case .summary:
            return AnyView(SummaryView(profileData: profileData))
            
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
