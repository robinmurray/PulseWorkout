//
//  SettingsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 31/10/2024.
//

import SwiftUI

struct SettingsView: View {
    
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @ObservedObject var bluetoothManager: BTDevicesController
    @ObservedObject var settingsManager: SettingsManager = SettingsManager.shared
    
    var body: some View {
        
 //       NavigationStack {

            Form {

                NavigationLink(
                    destination: AutoPauseSettingsView()) {
                        HStack {
                            Label("Auto-Pause", systemImage: "pause.circle")
                                .foregroundColor(.orange)
                            Spacer()
                        }
                    }
                
                NavigationLink(
                    destination: AverageSettingsView()) {
                        HStack {
                            Label("Average Calculations", systemImage: meanIcon)
                                .foregroundColor(.green)
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
                    destination: CyclingPowerSettingsView()) {
                        HStack {
                            Label("Cycling Power", systemImage: "bolt.circle")
                                .foregroundColor(.red)
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
                #if os(watchOS)
                NavigationLink(
                    destination: HapticsSettingsView()) {
                        HStack {
                            Label("Haptics", systemImage: "applewatch.radiowaves.left.and.right")
                                .foregroundColor(.teal)
                            Spacer()
                        }

                }
                #endif
                NavigationLink(
                    destination: CloudConnectionsView()) {
                        HStack {
                            Label("Apple Health", systemImage: "heart.text.clipboard")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                
                NavigationLink(
                    destination: StravaSettingsView()) {
                        HStack {
                            HStack{
                                Image("StravaIcon").resizable().frame(width: 30, height: 30)
                                Text("Strava Integration").foregroundColor(Color("StravaColor"))
                            }
                            Spacer()
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)

 //       }
        
    }

}

#Preview {
    let navigationCoordinator = NavigationCoordinator()
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    
    SettingsView(navigationCoordinator: navigationCoordinator,
                 bluetoothManager: bluetoothManager)
}
