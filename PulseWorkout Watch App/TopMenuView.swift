//
//  TopMenuView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 07/12/2023.
//

import SwiftUI
import WatchKit


struct TopMenuView: View {

    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var dataCache: DataCache

    enum NavigationTarget {
        case ActivityHistoryView
        case LocationView
        case NowPlayingView
        case SettingsView
    }
           
    
    var body: some View {

            ScrollView {
                
                VStack {
                    Button {
                        navigationCoordinator.goToView(targetView: NavigationTarget.ActivityHistoryView)
                    } label: {
                        HStack {

                            Image(systemName: "book.circle")
                                .foregroundColor(Color.black)
                                .font(.title2)
                                .background(Color.yellow)
                                .clipShape(Circle())
                            
                            Text("History")
                                .foregroundColor(Color.yellow)
                            
                            Spacer()
                        }
                    }
                    
                    Button {
                        navigationCoordinator.goToView(targetView: NavigationTarget.LocationView)
                    } label: {
                        HStack {
                            Image(systemName: "location.circle")
                                .foregroundColor(Color.black)
                                .font(.title2)
                                .background(Color.blue)
                                .clipShape(Circle())

                            Text("Location")
                                .foregroundColor(Color.blue)

                            Spacer()

                        }
                    }

                    Button {
                        navigationCoordinator.goToView(targetView: NavigationTarget.NowPlayingView)
                    } label: {
                        HStack {
                            Image(systemName: "music.note.list")
                                .foregroundColor(Color.black)
                                .font(.title2)
                                .background(Color.red)
                                .clipShape(Circle())

                            Text("Music")
                                .foregroundColor(Color.red)

                            Spacer()

                        }
                    }
                    
                    Button {
                        navigationCoordinator.goToView(targetView: NavigationTarget.SettingsView)
                    } label: {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(Color.black)
                                .font(.title2)
                                .background(Color.gray)
                                .clipShape(Circle())
                            
                            Text("Settings")
                                .foregroundColor(Color.gray)
                                
                            Spacer()
                        }
                    }
                }
            }
            .navigationDestination(for: NavigationTarget.self) { pathValue in
                
                if pathValue == .ActivityHistoryView {

                    ActivityHistoryView(navigationCoordinator: navigationCoordinator,
                                        dataCache: dataCache)
                }
                else if pathValue == .LocationView {
                    
                    LocationView(navigationCoordinator: navigationCoordinator,
                                 locationManager: liveActivityManager.locationManager)
                }
                else if pathValue == .NowPlayingView {
                    
                    NowPlayingView()
                }
                else if pathValue == .SettingsView {
                    
                    SettingsView(bluetoothManager: liveActivityManager.bluetoothManager,
                                              settingsManager: liveActivityManager.settingsManager)
                }
                else
                {
                    Text("Unknown Target View")
                }
                
            }

    }

}

struct TopMenuView_Previews: PreviewProvider {
    
    static var navigationCoordinator = NavigationCoordinator()
    static var profileManager = ProfileManager()
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache(settingsManager: settingsManager)
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         settingsManager: settingsManager,
                                                         dataCache: dataCache)
    
    static var previews: some View {
        TopMenuView(navigationCoordinator: navigationCoordinator,
                    profileManager: profileManager,
                    liveActivityManager: liveActivityManager,
                    dataCache: dataCache)
    }

}
