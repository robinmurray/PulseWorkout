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
                    destination: GeneralSettingsView(settingsManager: settingsManager)) {
                        HStack {
                            Label("General", systemImage: "folder")
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
                    destination: WatchAsDeviceView(settingsManager: settingsManager)) {
                        HStack {
                            Label("Watch as Sensor", systemImage: "applewatch.radiowaves.left.and.right")
                                .foregroundColor(.mint)
                            Spacer()
                        }

                }

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
    
    var bluetoothManager = BTDevicesController(requestedServices: nil)
    var settingsManager = SettingsManager()
    
    SettingsView(bluetoothManager: bluetoothManager,
                 settingsManager: settingsManager)
}
