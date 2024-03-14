//
//  TopMenuView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 07/12/2023.
//

import SwiftUI
import WatchKit


struct TopMenuView: View {

    @ObservedObject var profileManager: ActivityProfiles
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var dataCache: DataCache

           
//    @State var navigateToNowPlayingView: Bool = false
//    @State var navigateToLocationView: Bool = false
//    @State var navigateToHistoryView: Bool = false
//    @State var navigateToSettingsView: Bool = false

//    @State var selectedOption: Int = 0
    
    var body: some View {

        NavigationStack {

            ScrollView {
                
                VStack {
                    
                    NavigationLink(
                        destination: ActivityHistoryView(dataCache: dataCache)) {
                        HStack {
//                               Label("History", systemImage: "book.circle")
//                                    .foregroundColor(Color.yellow)
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

                    NavigationLink(
                        destination: LocationView(locationManager: liveActivityManager.locationManager)) {
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

                    NavigationLink(
                        destination: NowPlayingView()) {
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
                    
                    NavigationLink(
                        destination: SettingsView(bluetoothManager: liveActivityManager.bluetoothManager!,
                                                  settingsManager: liveActivityManager.settingsManager)) {
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
        }
    }

}

struct TopMenuView_Previews: PreviewProvider {
    
    static var profileManager = ActivityProfiles()
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache()
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager, settingsManager: settingsManager,
        dataCache: dataCache)
    
    static var previews: some View {
        TopMenuView(profileManager: profileManager,
                        liveActivityManager: liveActivityManager,
                    dataCache: dataCache)
    }

}
