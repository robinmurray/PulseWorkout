//
//  ProfileListView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 14/04/2023.
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
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle {
            Label("Profiles", systemImage: "figure.run")
                .foregroundColor(.orange)
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                HStack{
                    
                    NavigationStack {
                        Button {
                             navigateToTopMenuView = true
                        } label: {
                            Label("Add", systemImage: "list.triangle")
                        }
                    }
                    .navigationDestination(isPresented: $navigateToTopMenuView) {
                        TopMenuView( profileManager: profileManager, liveActivityManager: liveActivityManager, dataCache: dataCache)
                    }
                    
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
        }
    }
}


struct ProfileListView_Previews: PreviewProvider {

    static var profileManager = ProfileManager()
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache(settingsManager: settingsManager)
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         settingsManager: settingsManager,
                                                         dataCache: dataCache)

    
    static var previews: some View {
        ProfileListView(profileManager: profileManager,
                        liveActivityManager: liveActivityManager,
                        dataCache: dataCache)
    }
}


