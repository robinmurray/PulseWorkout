//
//  StopView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 22/12/2022.
//

import SwiftUI

struct StopView: View {

    @ObservedObject var workoutManager: WorkoutManager
    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }

    
    var body: some View {
        VStack{
             Button(action: lockScreen) {
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

                    Button(action: workoutManager.pauseWorkout) {
                            Image(systemName: "pause.circle")
                        }
                        .foregroundColor(Color.yellow)
                        .frame(width: 40, height: 40)
                        .font(.title)
                        .background(Color.clear)
                        .clipShape(Circle())
                        
                        Text("Pause")
                            .foregroundColor(Color.yellow)
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
            .navigationTitle("Workout Control")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func lockScreen() {
        WKInterfaceDevice.current().enableWaterLock()
        workoutManager.liveTabSelection = LiveScreenTab.liveMetrics
    }
}

struct StopView_Previews: PreviewProvider {
    
    static var workoutManager = WorkoutManager()

    static var previews: some View {
        StopView(workoutManager: workoutManager)
    }
}
