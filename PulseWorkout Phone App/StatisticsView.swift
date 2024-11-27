//
//  StatisticsView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 20/11/2024.
//

import SwiftUI
import HealthKit

struct DestinationView: View {
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    var type: String

    
    var body: some View {
        VStack {
            Text(type).font(.title)

//            Text("\(navigationPath)")
            Button("Back to root") {
                // to navigate to root view you simply pop all the views from navPath
                navigationCoordinator.statsPath.removeLast()
            }
            
            Button("Go!") {
  //              navigationCoordinator.goToTab(tab: .home)
                navigationCoordinator.statsPath.append(DestinationViewNavOptions.DestinationView)
            }
            .buttonStyle(.bordered)
        }
        .navigationDestination(for: DestinationViewNavOptions.self) { pathValue in

            if pathValue == DestinationViewNavOptions.DestinationView {

                DestinationView(navigationCoordinator: navigationCoordinator, type: "Hello World Again")
            }
            
        }

    }
    
}

enum DestinationViewNavOptions {
    case DestinationView
}
enum MyViews {
    case DestinationView
}
struct StatisticsView: View {
    
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var dataCache: DataCache

    
    var body: some View {
        VStack {
            ActivityHistoryHeaderView()
 
 
            Spacer()
            Text("Statistics!")
            Spacer()
            Button("Go!") {
                navigationCoordinator.goToTab(tab: .home)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .navigationDestination(for: MyViews.self) { pathValue in

            if pathValue == MyViews.DestinationView {

                DestinationView(navigationCoordinator: navigationCoordinator, type: "Hello World")
            }            
        }
    }
}

#Preview {

    let navigationCoordinator = NavigationCoordinator()
    let settingsManager = SettingsManager()
    let locationManager = LocationManager(settingsManager: settingsManager)
    let dataCache = DataCache(settingsManager: settingsManager)
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         settingsManager: settingsManager,
                                                         dataCache: dataCache)
    let profileManager = ProfileManager()
    
    
    StatisticsView(navigationCoordinator: navigationCoordinator,
                   profileManager: profileManager,
                   liveActivityManager: liveActivityManager,
                   dataCache: dataCache)
}

