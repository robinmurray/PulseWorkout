//
//  StartView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//


import Foundation


import SwiftUI


struct StartView: View {

    @ObservedObject var workoutManager: WorkoutManager
    @ObservedObject var profileManager: ActivityProfiles

    init(workoutManager: WorkoutManager, profileManager: ActivityProfiles) {
        self.workoutManager = workoutManager
        self.profileManager = profileManager
    }

    
    var body: some View {
        VStack {
            ProfileListView(profileManager: profileManager,
                            workoutManager: workoutManager)

            BTDeviceBarView(workoutManager: workoutManager)

            }
            .padding(.horizontal)
            .navigationTitle("Profiles")
            .navigationBarTitleDisplayMode(.inline)
        }
    }


struct StartView_Previews: PreviewProvider {
    static var workoutManager = WorkoutManager()
    static var profileManager = ActivityProfiles()

    static var previews: some View {
        StartView(workoutManager: workoutManager,
                  profileManager: profileManager)
    }
}
