//
//  WorkoutSelectionView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 22/12/2022.
//

import SwiftUI
import HealthKit

struct WorkoutSelectionView: View {

    @ObservedObject var workoutManager: WorkoutManager
    
    var workoutTypes: [HKWorkoutActivityType] = [.crossTraining, .cycling, .mixedCardio, .paddleSports, .rowing, .running, .walking]
    
    var workoutLocations: [HKWorkoutSessionLocationType] = [.indoor, .outdoor, .unknown]

    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }


    var body: some View {
        VStack{
            Form() {
                
                Picker("Workout Type", selection: $workoutManager.workoutType) {
                    ForEach(workoutTypes) { workoutType in
                        Text(workoutType.name).tag(workoutType.self)
                    }
                }
                .onChange(of: workoutManager.workoutType) { _ in
                    self.workoutManager.writeWorkoutConfToUserDefaults()
                }
                .font(.headline)
                .foregroundColor(Color.blue)
                .fontWeight(.bold)
                .listStyle(.carousel)

                Picker("Workout Location", selection: $workoutManager.workoutLocation) {
                    ForEach(workoutLocations) { workoutLocation in
                        Text(workoutLocation.name).tag(workoutLocation.self)
                    }
                }
                .onChange(of: workoutManager.workoutLocation) { _ in
                    self.workoutManager.writeWorkoutConfToUserDefaults()
                }
                .font(.headline)
                .foregroundColor(Color.blue)
                .fontWeight(.bold)
                .listStyle(.carousel)

            }
        }
        .navigationTitle("Workout Type")
        .navigationBarTitleDisplayMode(.inline)
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
    
    var label: String {
        switch self {
        case .unknown:
            return ""
        default:
            return self.name
        }
    }
}


struct WorkoutSelectionView_Previews: PreviewProvider {
    static var workoutManager = WorkoutManager()

    static var previews: some View {
        WorkoutSelectionView(workoutManager: workoutManager)
    }
}
