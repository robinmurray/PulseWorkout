//
//  ProfileListView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 18/11/2024.
//

import SwiftUI

struct ProfileListView: View {

    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var dataCache: DataCache
    
    @State private var navigateToNewView : Bool = false
    @State private var navigateToTopMenuView : Bool = false
    
    
    var body: some View {
        

        List {
            ForEach(profileManager.profiles) { profile in
                // Pass binding to item into DetailsView
                ProfileListItemView(profile:  self.$profileManager.profiles[self.profileManager.profiles.firstIndex(where: { $0.id == profile.id })!],
                                    profileManager: profileManager,
                                    liveActivityManager: liveActivityManager,
                                    dataCache: dataCache)
            }

        }
        .listStyle(.grouped)
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                HStack{
                    
                    NavigationStack {
                        Button {
                            navigateToNewView = true
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                    }
                    .navigationDestination(isPresented: $navigateToNewView) {
                        NewProfileDetailView(profileManager: profileManager)
                    }

                }

            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                HStack {
                    Text("Activity Profiles")
                    Spacer()
                    Image(systemName: "figure.run")
                }.foregroundColor(.orange)
            }
        }
        
    }
}


#Preview {
    let profileManager = ProfileManager()
    let settingsManager = SettingsManager()
    let locationManager = LocationManager(settingsManager: settingsManager)
    let dataCache = DataCache(settingsManager: settingsManager)
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         settingsManager: settingsManager,
                                                         dataCache: dataCache)
    
    ProfileListView(profileManager: profileManager,
                    liveActivityManager: liveActivityManager,
                    dataCache: dataCache)
}
