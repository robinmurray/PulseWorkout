//
//  WorkoutManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 23/12/2022.
//

import Foundation
import HealthKit

class WorkoutManager: NSObject, ObservableObject {
    
    var selectedWorkout: HKWorkoutActivityType?
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    
    func startWorkout(workoutType: HKWorkoutActivityType) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession( healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            print("Failed to start Workout Session")
            return
        }
        
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
     
        // Start the session and collect data
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            // workout started
        }
        
    }
    
    func requestAuthorization() {
        // the quantity type to write to healthStore
        let typesToShare: Set = [HKWorkoutType.workoutType()]
        
        // the quantity types to read from healthStore
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]

        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)  { (success, error) in
            if !success {
                // Handle the error here.
                print("Authorisation Failed")
            }
        }
    }
}
