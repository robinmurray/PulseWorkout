//
//  StartView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//


import Foundation


import SwiftUI

struct NewView: View {
    var body: some View {
        Text("New")
    }
    
}

struct StartView: View {

    @ObservedObject var workoutManager: WorkoutManager

//    @State private var profileNames: [String] = ["Race", "VO2 Max", "Threshold", "Aerobic"]

    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }

    
    var body: some View {
        VStack {
            List(workoutManager.activityProfiles.UIProfileList()) { activityProfile in
                ActivityProfileView(workoutManager: workoutManager, activityProfile: activityProfile)
            }
            .listStyle(.carousel)

            BTDevicesView(workoutManager: workoutManager)

            }
            .padding(.horizontal)
            .navigationTitle("Start Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
}

struct StartView_Previews: PreviewProvider {
    static var workoutManager = WorkoutManager()

    static var previews: some View {
        StartView(workoutManager: workoutManager)
    }
}
