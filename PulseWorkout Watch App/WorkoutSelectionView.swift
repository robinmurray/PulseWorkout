//
//  WorkoutSelectionView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 22/12/2022.
//

import SwiftUI
import HealthKit

struct WorkoutSelectionView: View {

    @ObservedObject var profileData: ProfileData
    
    var workoutTypes: [HKWorkoutActivityType] = [.crossTraining, .cycling, .mixedCardio, .paddleSports, .rowing, .running, .walking]
    
    var workoutLocations: [HKWorkoutSessionLocationType] = [.indoor, .outdoor, .unknown]

    @State private var currentWorkoutType: HKWorkoutActivityType = HKWorkoutActivityType.cycling
    @State private var currentWorkoutLocation: HKWorkoutSessionLocationType = HKWorkoutSessionLocationType.outdoor

    init(profileData: ProfileData) {
        self.profileData = profileData
    }


    var body: some View {
        VStack{
            Form() {
                
                Picker("Workout Type", selection: $profileData.currentWorkoutType) {
                    ForEach(workoutTypes) { workoutType in
                        Text(workoutType.name).tag(workoutType.self)
                    }
                }
//                .onChange(of: profileData.currentWorkoutType) { _ in
//                    workoutTypeChanged(newSelectedWorkoutType: currentWorkoutType )
//                }
                .onChange(of: profileData.currentWorkoutType) { _ in
                    self.profileData.WriteToUserDefaults(profileName: profileData.profileName)
                }
                .font(.headline)
                .foregroundColor(Color.blue)
                .fontWeight(.bold)
                .listStyle(.carousel)

                Picker("Workout Location", selection: $currentWorkoutLocation) {
                    ForEach(workoutLocations) { workoutLocation in
                        Text(workoutLocation.name).tag(workoutLocation.self)
                    }
                }
//                .onChange(of: currentWorkoutType) { _ in
//                    workoutTypeChanged(newSelectedWorkoutType: currentWorkoutType )
//                }
                .font(.headline)
                .foregroundColor(Color.blue)
                .fontWeight(.bold)
                .listStyle(.carousel)

            }
        }
    }
    
    func workoutTypeChanged(newSelectedWorkoutType: HKWorkoutActivityType){
        print("picker changed! to \(newSelectedWorkoutType)")
        
        self.currentWorkoutType = newSelectedWorkoutType
        profileData.selectedWorkout = newSelectedWorkoutType
    }

}


extension HKWorkoutActivityType: Identifiable {
    public var id: UInt {
        rawValue
    }
    
    var name: String {
        switch self {
        case .crossTraining:
            return "Cross Training"
        case .cycling:
            return "Cycling"
        case .mixedCardio:
            return "Mixed Cardio"
        case .paddleSports:
            return "Paddle Sports"
        case .rowing:
            return "Rowing"
        case .running:
            return "Running"
        case .walking:
            return "Walking"
        default:
            return ""
        }
    }
}


extension HKWorkoutSessionLocationType: Identifiable {
    public var id: Int {
        rawValue
    }
    
    var name: String {
        switch self {
        case .indoor:
            return "Indoor"
        case .outdoor:
            return "Outdoor"
        case .unknown:
            return "Unknown"
        default:
            return ""
        }
    }
}


struct WorkoutSelectionView_Previews: PreviewProvider {
    static var profileData = ProfileData()

    static var previews: some View {
        WorkoutSelectionView(profileData: profileData)
    }
}
