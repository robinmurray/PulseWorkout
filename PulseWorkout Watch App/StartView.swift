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

//    @State private var profileNames: [String] = ["Race", "VO2 Max", "Threshold", "Aerobic"]

    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }

    
    var body: some View {
        VStack {
 //           Picker("Profile", selection: $workoutManager.profileName) {
 //               ForEach(profileNames, id: \.self) { status in
 //                   ActivityProfileView(workoutManager: workoutManager)
 //               }
 //           }

            ActivityProfileView(workoutManager: workoutManager)

            Spacer().frame(maxWidth: .infinity)
       
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
