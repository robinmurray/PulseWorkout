//
//  ContentView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import SwiftUI


enum AppState {
    case initial, live, paused, summary, discoverDevices
}

struct ContentView: View {

    @ObservedObject var profileData = ProfileData()

    var body: some View {
        
        containedView()
    }
        
    func containedView() -> AnyView {
        
        switch profileData.appState {
            
        case .initial:
            return AnyView(StartTabView(profileData: profileData))
            
        case .live:
            return AnyView(LiveTabView(profileData: profileData)
                )
            
        case .paused:
            return AnyView(PausedTabView(profileData: profileData))
            
        case .summary:
            return AnyView(SummaryTabView(profileData: profileData))

        case .discoverDevices:
            return AnyView(BTDeviceDiscoverView(profileData: profileData))

        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
