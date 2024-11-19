//
//  SettingsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 31/10/2024.
//

import SwiftUI

struct SettingsView: View {
    
    @ObservedObject var bluetoothManager: BTDevicesController
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        
        NavigationStack {

            Form {

                NavigationLink(
                    destination: AutoPauseSettingsView(settingsManager: settingsManager)) {
                        HStack {
                            Label("Auto-Pause", systemImage: "pause.circle")
                                .foregroundColor(.orange)
                            Spacer()
                        }
                    }
                
                NavigationLink(
                    destination: AverageSettingsView(settingsManager: settingsManager)) {
                        HStack {
                            Label("Average Calculations", systemImage: "arrow.up.and.line.horizontal.and.arrow.down")
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
                    destination: CyclingPowerSettingsView(settingsManager: settingsManager)) {
                        HStack {
                            Label("Cycling Power", systemImage: "bolt.circle")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                
                NavigationLink(
                    destination: WatchAsDeviceView(settingsManager: settingsManager)) {
                        HStack {
                            Label("Watch as Sensor", systemImage: "applewatch.radiowaves.left.and.right")
                                .foregroundColor(.mint)
                            Spacer()
                        }

                }
                #if os(watchOS)
                NavigationLink(
                    destination: HapticsSettingsView(settingsManager: settingsManager)) {
                        HStack {
                            Label("Haptics", systemImage: "applewatch.radiowaves.left.and.right")
                                .foregroundColor(.teal)
                            Spacer()
                        }

                }
                #endif
                NavigationLink(
                    destination: CloudConnectionsView(settingsManager: settingsManager)) {
                        HStack {
                            Label("Cloud Connections", systemImage: "cloud")
                                .foregroundColor(.gray)
                            Spacer()
                        }
                    }

            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)

        }
        
    }

}

#Preview {
    
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    let settingsManager = SettingsManager()
    
    SettingsView(bluetoothManager: bluetoothManager,
                 settingsManager: settingsManager)
}
