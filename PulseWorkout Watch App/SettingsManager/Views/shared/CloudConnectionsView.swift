//
//  CloudConnectionsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 11/09/2023.
//

import SwiftUI


struct CloudConnectionsView: View {
    
    @ObservedObject var settingsManager: SettingsManager
    
    var body: some View {
            Form {
                VStack {
                    Toggle(isOn: $settingsManager.saveAppleHealth) {
                        Text("Apple Health")
                    }
                    HStack {
                        Text("Save activity summaries to apple health.")
                            .font(.footnote).foregroundColor(.gray)
                        Spacer()
                    }

                }

                VStack {
                    Toggle(isOn: $settingsManager.saveStrava) {
                        Text("Strava")
                    }
                    HStack {
                        Text("Save activities and routes to Strava.")
                            .font(.footnote).foregroundColor(.gray)
                        Spacer()
                    }
                }

                VStack {
                    Button("Clear local cache") {
                        clearCache()
                    }.buttonStyle(.borderedProminent)
                        .tint(Color.blue)
                    
                    HStack {
                        Text("Delete locally stored activities that have not been uploaded to cloud storage.")
                            .font(.footnote).foregroundColor(.gray)
                        Spacer()
                    }

                }


            }
#if os(watchOS)
            .navigationTitle {
                Label("Cloud Connections", systemImage: "cloud")
                    .foregroundColor(.gray)
            }
#else
            .navigationTitle("Cloud Connections")
#endif
            .onDisappear(perform: settingsManager.save)
        }
        

}

struct CloudConnectionsView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()

    static var previews: some View {
        CloudConnectionsView(settingsManager: settingsManager)
    }
}
