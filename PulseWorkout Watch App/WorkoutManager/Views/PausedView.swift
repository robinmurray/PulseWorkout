//
//  PausedView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 23/12/2022.
//

import SwiftUI

struct PausedView: View {

    @ObservedObject var workoutManager: WorkoutManager

    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }


    var body: some View {
        VStack{
             Button(action: lockAndResumeWorkout) {
                Image(systemName: "drop.circle")
            }
            .foregroundColor(Color.blue)
            .frame(width: 40, height: 40)
            .font(.title)
            .background(Color.clear)
            .clipShape(Circle())
            
            Text("Lock")
                .foregroundColor(Color.blue)


            HStack{

                Spacer()

                VStack{

                        Button(action: workoutManager.resumeWorkout) {
                            Image(systemName: "playpause.circle.fill")
                        }
                        .foregroundColor(Color.green)
                        .frame(width: 40, height: 40)
                        .font(.title)
                        .background(Color.clear)
                        .clipShape(Circle())
                        
                        Text("Resume")
                            .foregroundColor(Color.green)
                    }

                Spacer()

                VStack{
                    Button(action: workoutManager.endWorkout) {
                        Image(systemName: "stop.circle")
                    }
                    .foregroundColor(Color.red)
                    .frame(width: 40, height: 40)
                    .font(.title)
                    .background(Color.clear)
                    .clipShape(Circle())
                    
                    Text("Stop")
                        .foregroundColor(Color.red)
                    
                }

                Spacer()
            }

        }
        .navigationTitle("Workout Paused")
        .navigationBarTitleDisplayMode(.inline)
    }

    
    func lockAndResumeWorkout() {
        WKInterfaceDevice.current().enableWaterLock()
        workoutManager.resumeWorkout()
    }
}


struct PausedView_Previews: PreviewProvider {
    
    static var activityDataManager = ActivityDataManager()
    static var locationManager = LocationManager(activityDataManager: activityDataManager)
    static var workoutManager = WorkoutManager(locationManager: locationManager, activityDataManager: activityDataManager)
    
    static var previews: some View {
        PausedView(workoutManager: workoutManager)
    }
}
