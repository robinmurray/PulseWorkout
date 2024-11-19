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
                VStack {
                    Toggle(isOn: $settingsManager.transmitHR) {
                        Text("Heart Rate")
                    }
                    
                    HStack {
                        Text("Make Apple watch appear as a bluetooth Heart Rate Monitor, transmitting data either from watch pulse meter or from a connected heart rate monitor.")
                            .font(.footnote).foregroundColor(.gray)
                        Spacer()
                    }

                }
                
                VStack {
                    Toggle(isOn: $settingsManager.transmitPowerMeter) {
                        Text("Power Meter")
                    }

                    HStack {
                        Text("Make Apple watch appear as a bluetooth power meter transmitting data from a connected real power meter.")
                            .font(.footnote).foregroundColor(.gray)
                        Spacer()
                    }

                }

            }
#if os(watchOS)
            .navigationTitle {
                Label("Watch as Sensor", systemImage: "applewatch.radiowaves.left.and.right")
                    .foregroundColor(.mint)
            }
#else
            .navigationTitle("Watch as Sensor")
#endif
            .onDisappear(perform: settingsManager.save)
        }
        

}

struct WatchAsDeviceView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    
    static var previews: some View {
        WatchAsDeviceView(settingsManager: settingsManager)
    }
}
