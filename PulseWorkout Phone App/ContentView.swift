//
//  ContentView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 29/10/2024.
//

import SwiftUI

struct ContentView: View {
//    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var dataCache: DataCache
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var bluetoothManager: BTDevicesController

    var body: some View {
        
        TabView {
            ActivityHistoryView(dataCache: dataCache)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            Text("Activities!")
                .tabItem {
                    Label("Activities", systemImage: "figure.run")
                }
            
            VStack {
                ActivityHistoryHeaderView()
                Spacer()
                Text("Statistics!")
                Spacer()
            }
                .tabItem {

                    Label("Stats", systemImage: "person")
                }

                    
            SettingsView(bluetoothManager: bluetoothManager,
                         settingsManager: settingsManager)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
            }

        }
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))

//        .onAppear(perform: liveActivityManager.requestAuthorization)

    }

}



#Preview {

    let settingsManager = SettingsManager()
    let locationManager = LocationManager(settingsManager: settingsManager)
    let dataCache = DataCache(settingsManager: settingsManager)
    let profileManager = ProfileManager()
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    
    ContentView(profileManager: profileManager,
                dataCache: dataCache,
                settingsManager: settingsManager,
                locationManager: locationManager,
                bluetoothManager: bluetoothManager)
}
