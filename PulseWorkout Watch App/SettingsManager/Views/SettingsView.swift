//
//  SettingsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 08/09/2023.
//

import SwiftUI

struct SettingsView: View {
    
    @ObservedObject var bluetoothManager: BTDevicesController
    
    var body: some View {
        NavigationStack {
            ScrollView {

            VStack {

                NavigationLink(
                    destination: BTContentView(bluetoothManager: bluetoothManager)) {
                        HStack {
                            Label("General", systemImage: "folder")
                            Spacer()
                        }
                        
                    }
                    .buttonStyle(.borderedProminent)
 //               .tint(Color.blue)

                NavigationLink(
                    destination: BTContentView(bluetoothManager: bluetoothManager)) {
                        HStack {
                            Label("Devices", systemImage: "badge.plus.radiowaves.right")
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
 //               .tint(Color.blue)

                NavigationLink(
                    destination: BTContentView(bluetoothManager: bluetoothManager)) {
                        HStack {
                            Label("Watch as Device", systemImage: "applewatch.radiowaves.left.and.right")
                            Spacer()
                        }

                }
                .buttonStyle(.borderedProminent)
 //               .tint(Color.blue)


                NavigationLink(
                    destination: BTContentView(bluetoothManager: bluetoothManager)) {
                        HStack {
                            Label("Strava", systemImage: "figure.outdoor.cycle")
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
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


    static var previews: some View {
        SettingsView(bluetoothManager: bluetoothManager)
    }
}
