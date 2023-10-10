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

    @State private var navigateToDetailView : Bool = false
    @State var newId: UUID?
    
    
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
                        //Code here before changing the bool value
                        newId = profileManager.addNew()
                        
                        navigateToDetailView = true
                    } label: {
                        Text("New Profile")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.green)
                }
                .navigationDestination(isPresented: $navigateToDetailView) {
                    ProfileDetailView(profileManager: profileManager, profileIndex: profileManager.profiles.firstIndex(where: { $0.id == newId }) ?? 0)
                }
            }
            
        }
    }
}


struct ProfileListView_Previews: PreviewProvider {

    static var activityDataManager = ActivityDataManager()
    static var profileManager = ActivityProfiles()
    static var locationManager = LocationManager(activityDataManager: activityDataManager)
    static var settingsManager = SettingsManager()
    static var workoutManager = WorkoutManager(locationManager: locationManager, activityDataManager: activityDataManager,
        settingsManager: settingsManager)

    
    static var previews: some View {
        ProfileListView(profileManager: profileManager,
                        workoutManager: workoutManager,
                        activityDataManager: activityDataManager)
    }
}


