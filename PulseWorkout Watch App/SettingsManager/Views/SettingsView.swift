//
//  SettingsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 08/09/2023.
//

import SwiftUI

struct SettingsView: View {
    
    @ObservedObject var bluetoothManager: BTDevicesController
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
        NavigationStack {
            ScrollView {

            VStack {

                NavigationLink(
                    destination: GeneralSettingsView(settingsManager: settingsManager)) {
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
            .navigationTitle {
                Label("Settings", systemImage: "gear")
                    .foregroundColor(.gray)
            }

        }

        }
        
    }

}

struct SettingsView_Previews: PreviewProvider {
    
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    static var settingsManager = SettingsManager()

    static var previews: some View {
        SettingsView(bluetoothManager: bluetoothManager, settingsManager: settingsManager)
    }
}
