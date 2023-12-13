//
//  WatchAsDeviceView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 09/09/2023.
//

import SwiftUI

struct WatchAsDeviceView: View {
    
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
            Form {
                
                Toggle(isOn: $settingsManager.transmitHR) {
                    Text("Heart Rate")
                }
                
                Text("Make Apple watch appear as a bluetooth Heart Rate Monitor, transmitting data either from watch pulse meter or from a connected heart rate monitor.")
                    .font(.footnote).foregroundColor(.gray)

                Toggle(isOn: $settingsManager.transmitPowerMeter) {
                    Text("Power Meter")
                }

                Text("Make Apple watch appear as a bluetooth power meter transmitting data from a connected real power meter.")
                    .font(.footnote).foregroundColor(.gray)

            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onDisappear(perform: settingsManager.save)
        }
        

}

struct WatchAsDeviceView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    
    static var previews: some View {
        WatchAsDeviceView(settingsManager: settingsManager)
    }
}
