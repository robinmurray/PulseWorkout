//
//  CloudConnectionsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 11/09/2023.
//

import SwiftUI


struct CloudConnectionsView: View {
    
    @ObservedObject var settingsManager: SettingsManager = SettingsManager.shared
    
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


            }
#if os(watchOS)
            .navigationTitle {
                Label("Apple Health", systemImage: "cloud")
                    .foregroundColor(.gray)
            }
#else
            .navigationTitle("Apple Health")
#endif
            .onDisappear(perform: settingsManager.save)
        }
        

}

struct CloudConnectionsView_Previews: PreviewProvider {

    static var previews: some View {
        CloudConnectionsView()
    }
}
