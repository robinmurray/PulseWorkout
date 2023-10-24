//
//  ProfileListView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 14/04/2023.
//

import SwiftUI

struct ProfileListView: View {

    @ObservedObject var profileManager: ActivityProfiles
    @ObservedObject var workoutManager: WorkoutManager
    @ObservedObject var activityDataManager: ActivityDataManager

     @State private var navigateToNewView : Bool = false

    @State var newProfileIndex: Int = 0
    
    
    var body: some View {
        
        List {
            ForEach(profileManager.profiles) { profile in
                // Pass binding to item into DetailsView
                ProfileListItemView(profile:  self.$profileManager.profiles[self.profileManager.profiles.firstIndex(where: { $0.id == profile.id })!],
                                    profileManager: profileManager,
                                    workoutManager: workoutManager,
                                    activityDataManager: activityDataManager)
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

    static var activityDataManager = ActivityDataManager()
    static var profileManager = ActivityProfiles()
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(activityDataManager: activityDataManager, settingsManager: settingsManager)

    static var workoutManager = WorkoutManager(locationManager: locationManager, activityDataManager: activityDataManager,
        settingsManager: settingsManager)

    
    static var previews: some View {
        ProfileListView(profileManager: profileManager,
                        workoutManager: workoutManager,
                        activityDataManager: activityDataManager)
    }
}


