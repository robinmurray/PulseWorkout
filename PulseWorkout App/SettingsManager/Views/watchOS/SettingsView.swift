//
//  SettingsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 08/09/2023.
//

import SwiftUI

struct SettingsView: View {
    
    @ObservedObject var bluetoothManager: BTDevicesController
    @ObservedObject var settingsManager: SettingsManager = SettingsManager.shared
    @ObservedObject var dataCache: DataCache
    
    var body: some View {
//        NavigationStack {
            ScrollView {

            VStack {

                NavigationLink(
                    destination: GeneralSettingsView()) {
                        HStack {
                            Label("General", systemImage: "folder")
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                    }

                NavigationLink(
                    destination: BTContentView(bluetoothManager: bluetoothManager)) {
                        HStack {
                            Label("Sensors", systemImage: "badge.plus.radiowaves.right")
                                .foregroundColor(.blue)
                            Spacer()
                        }
                    }

                NavigationLink(
                    destination: WatchAsDeviceView()) {
                        HStack {
                            Label("Watch as Sensor", systemImage: "applewatch.radiowaves.left.and.right")
                                .foregroundColor(.mint)
                            Spacer()
                        }

                }

                NavigationLink(
                    destination: CloudConnectionsView()) {
                        HStack {
                            Label("Cloud Connections", systemImage: "cloud")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }
                
                NavigationLink(
                    destination: StravaSettingsView(dataCache: dataCache)) {
                        HStack {
                            Image("StravaIcon").resizable().frame(width: 30, height: 30)
                            HStack{
                                Text("Strava Integration").foregroundColor(.white).multilineTextAlignment(.leading)
                                Spacer()
                            }
                        }
                    }
                
                NavigationLink(
                    destination: SettingsResetView()) {
                        HStack {
                            Label("Reset", systemImage: "gearshape")
                                .foregroundColor(.indigo)
                            Spacer()
                        }
                    }

                }
                .navigationTitle {
                Label("Settings", systemImage: "gear")
                    .foregroundColor(.gray)
                }

            }
            
//        }
        
    }

}

struct SettingsView_Previews: PreviewProvider {
    
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    static var dataCache = DataCache()

    static var previews: some View {
        SettingsView(bluetoothManager: bluetoothManager, dataCache: dataCache)
    }
}
