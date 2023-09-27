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
    var activityDataManager: ActivityDataManager
    
    var body: some View {
        NavigationStack {
            ScrollView {

            VStack {

                NavigationLink(
                    destination: GeneralSettingsView(settingsManager: settingsManager)) {
                        HStack {
                            Label("General", systemImage: "folder")
                            Spacer()
                        }
                        
                    }
 //                   .buttonStyle(.borderedProminent)
 //               .tint(Color.blue)

                NavigationLink(
                    destination: BTContentView(bluetoothManager: bluetoothManager)) {
                        HStack {
                            Label("Sensors", systemImage: "badge.plus.radiowaves.right")
                            Spacer()
                        }
                    }
 //                   .buttonStyle(.borderedProminent)
 //               .tint(Color.blue)

                NavigationLink(
                    destination: WatchAsDeviceView(settingsManager: settingsManager)) {
                        HStack {
                            Label("Watch as Sensor", systemImage: "applewatch.radiowaves.left.and.right")
                            Spacer()
                        }

                }
 //               .buttonStyle(.borderedProminent)
 //               .tint(Color.blue)


                NavigationLink(
                    destination: CloudConnectionsView(settingsManager: settingsManager, activityDataManager: activityDataManager)) {
                        HStack {
                            Label("Cloud Connections", systemImage: "cloud")
                            Spacer()
                        }
                    }
//                    .buttonStyle(.borderedProminent)
//                .tint(Color.blue)


            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }

        }
        
    }

}

struct SettingsView_Previews: PreviewProvider {
    
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    static var settingsManager = SettingsManager()
    static var activityDataManager = ActivityDataManager()


    static var previews: some View {
        SettingsView(bluetoothManager: bluetoothManager, settingsManager: settingsManager, activityDataManager: activityDataManager)
    }
}
