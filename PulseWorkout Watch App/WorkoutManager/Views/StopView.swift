//
//  StopView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 22/12/2022.
//

import SwiftUI

struct StopView: View {

    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var dataCache: DataCache
    @State private var navigateToSummaryView : Bool = false

    
    var body: some View {
        NavigationStack {
            VStack{
                Button(action: lockScreen) {
                    Image(systemName: "drop.circle")
                }
                .foregroundColor(Color.blue)
                .frame(width: 40, height: 40)
                .font(.title2)
                .background(Color.clear)
                .clipShape(Circle())
                
                Text("Lock")
                    .foregroundColor(Color.blue)
                
                HStack{
                    
                    Spacer()
                    
                    VStack{
                        
                        Button(action: liveActivityManager.pauseWorkout) {
                            Image(systemName: "pause.circle")
                        }
                        .foregroundColor(Color.yellow)
                        .frame(width: 40, height: 40)
                        .font(.title2)
                        .background(Color.clear)
                        .clipShape(Circle())
                        
                        Text("Pause")
                            .foregroundColor(Color.yellow)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Button {
                            liveActivityManager.endWorkout()
                            navigateToSummaryView = true
                        } label: {
                            VStack{
                                Image(systemName: "stop.circle")
                                    .foregroundColor(Color.red)
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .background(Color.clear)
                                    .clipShape(Circle())
                                    .buttonStyle(PlainButtonStyle())
                                
                                Text("Stop")
                                    .foregroundColor(Color.red)
                            }
                            
                        }
                        .tint(Color.red)
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .navigationDestination(isPresented: $navigateToSummaryView) {
                        ActivitySaveView(liveActivityManager: liveActivityManager,
                                         dataCache: dataCache)
                    }
                    
                    Spacer()
                }
                .navigationTitle("Activity Control")
                .navigationBarTitleDisplayMode(.large)
            }
        }
    }
    
    func lockScreen() {
        WKInterfaceDevice.current().enableWaterLock()
        liveActivityManager.liveTabSelection = LiveScreenTab.liveMetrics
    }
}

struct StopView_Previews: PreviewProvider {

    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache()
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager, settingsManager: settingsManager,
        dataCache: dataCache)


    static var previews: some View {
        StopView(liveActivityManager: liveActivityManager, dataCache: dataCache)
    }
}
