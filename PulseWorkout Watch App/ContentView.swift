//
//  ContentView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import SwiftUI

enum Tab {
    case start, active, monitor, stop, profile, nowPlaying, help, summary, summaryStats, workoutType
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
            return AnyView(ActiveView(profileData: profileData))
            
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
