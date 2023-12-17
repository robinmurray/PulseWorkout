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

           
    @State var navigateToNowPlayingView: Bool = false
    @State var navigateToLocationView: Bool = false
    @State var navigateToHistoryView: Bool = false
    @State var navigateToSettingsView: Bool = false

    @State var selectedOption: Int = 0
    
    var body: some View {
        /*
        NavigationSplitView {
            
            VStack {
                
                HStack {
                    Button {
                        navigateTo = 0
                    } label: {
                        Image(systemName: "figure.outdoor.cycle")
                    }
                    .foregroundColor(Color.black)
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .background(Color.green)
                    .clipShape(Circle())
                    .buttonStyle(PlainButtonStyle())
                    .padding([.bottom], 20)
                    
                    
                    Button {
                        navigateTo = 1
                    } label: {
                        Image(systemName: "location.circle")
                    }
                    .foregroundColor(Color.black)
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .background(Color.blue)
                    .clipShape(Circle())
                    .buttonStyle(PlainButtonStyle())
                    .padding([.bottom], 20)
                }
                
                
                HStack {
                    
                    Button {
                        navigateTo = 2
                    } label: {
                        Image(systemName: "book.circle")
                    }
                    .foregroundColor(Color.black)
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .background(Color.yellow)
                    .clipShape(Circle())
                    .buttonStyle(PlainButtonStyle())
                    .padding([.bottom], 40)
                    
                    Button {
                        navigateToSettingsView = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .foregroundColor(Color.black)
                    .font(.title)
                    .frame(width: 60, height: 60)
                    .background(Color.gray)
                    .clipShape(Circle())
                    .buttonStyle(PlainButtonStyle())
                    .padding([.bottom], 40)
                }
                
            }
        } detail : {
            
            if navigateTo == 0 {StartView(liveActivityManager: liveActivityManager,
                                         profileManager: profileManager,
                                         dataCache: dataCache)}
        }
*/

        VStack {
            
            Spacer()

            HStack {
                Spacer()
                
                NavigationStack {
                    VStack {
                        Button {
                            navigateToHistoryView = true
                        } label: {
                            VStack {
                                Image(systemName: "book.circle")
                                    .foregroundColor(Color.black)
                                    .font(.title)
                                    .frame(width: 60, height: 60)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                                Text("History")
                                    .foregroundColor(Color.orange)
                            }

                        }
                        .buttonStyle(PlainButtonStyle())

                    }

                }
                .navigationDestination(isPresented: $navigateToHistoryView) {
                    ActivityHistoryView(dataCache: dataCache)
                }
                
                Spacer()
                
                NavigationStack {
                    Button {
                        navigateToLocationView = true
                    } label: {
                        VStack {
                            Image(systemName: "location.circle")
                                .foregroundColor(Color.black)
                                .font(.title)
                                .frame(width: 60, height: 60)
                                .background(Color.blue)
                                .clipShape(Circle())
                            
                            Text("Location")
                                .foregroundColor(Color.blue)
                            
                        }
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .navigationDestination(isPresented: $navigateToLocationView) {
                    LocationView(locationManager: liveActivityManager.locationManager)
                }
                Spacer()
            }
            
            Spacer()
            
            HStack {
                Spacer()
                NavigationStack {
                    Button {
                        navigateToNowPlayingView = true
                    } label: {
                        VStack {
                            Image(systemName: "music.note.list")
                                .foregroundColor(Color.black)
                                .font(.title)
                                .frame(width: 60, height: 60)
                                .background(Color.red)
                                .clipShape(Circle())
                            Text("Music")
                                .foregroundColor(Color.red)
                        }
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .navigationDestination(isPresented: $navigateToNowPlayingView) {
                    NowPlayingView()
                }

                Spacer()
                
                NavigationStack {
                    Button {
                        navigateToSettingsView = true
                    } label: {
                        VStack {
                            Image(systemName: "gear")
                                .foregroundColor(Color.black)
                                .font(.title)
                                .frame(width: 60, height: 60)
                                .background(Color.gray)
                                .clipShape(Circle())
                            Text("Settings")
                                .foregroundColor(Color.gray)
                        }
                        
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .navigationDestination(isPresented: $navigateToSettingsView) {
                    SettingsView(bluetoothManager: liveActivityManager.bluetoothManager!,
                                 settingsManager: liveActivityManager.settingsManager)
                }
                
                Spacer()
            }

            Spacer()
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
