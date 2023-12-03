//
//  ProfileListView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 14/04/2023.
//

import SwiftUI

struct ProfileListView: View {

    @ObservedObject var profileManager: ActivityProfiles
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var dataCache: DataCache

     @State private var navigateToNewView : Bool = false

    @State var newProfileIndex: Int = 0
    
    
    var body: some View {
        
        List {
            ForEach(profileManager.profiles) { profile in
                // Pass binding to item into DetailsView
                ProfileListItemView(profile:  self.$profileManager.profiles[self.profileManager.profiles.firstIndex(where: { $0.id == profile.id })!],
                                    profileManager: profileManager,
                                    liveActivityManager: liveActivityManager,
                                    dataCache: dataCache)
            }
            
            NavigationStack {
                VStack {
                    Button {
                        navigateToNewView = true
                    } label: {
                        Text("New Profile")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.green)
                }
                .navigationDestination(isPresented: $navigateToNewView) {
                    NewProfileDetailView(profileManager: profileManager)
                }
            }
            
        }
    }
}


struct ProfileListView_Previews: PreviewProvider {

    static var profileManager = ActivityProfiles()
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache()
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager, settingsManager: settingsManager,
        dataCache: dataCache)

    
    static var previews: some View {
        ProfileListView(profileManager: profileManager,
                        liveActivityManager: liveActivityManager,
                        dataCache: dataCache)
    }
}


