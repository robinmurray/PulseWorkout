//
//  StopView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 22/12/2022.
//

import SwiftUI

struct StopView: View {

    @ObservedObject var workoutManager: WorkoutManager
    @State private var navigateToSummaryView : Bool = false
    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }

    
    var body: some View {
        NavigationStack {
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
                    
                    VStack {
                        Button {
                            workoutManager.endWorkout()
                            navigateToSummaryView = true
                        } label: {
                            VStack{
                                Image(systemName: "stop.circle")
                                    .foregroundColor(Color.red)
                                    .font(.title)
                                    .frame(width: 40, height: 40)
                                    .background(Color.clear)
                                    .clipShape(Circle())
                                    .buttonStyle(PlainButtonStyle())
                                
                                Text("Stop")
                                    .foregroundColor(Color.red)
                            }
                            
                        }
                        .tint(Color.red)
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .navigationDestination(isPresented: $navigateToSummaryView) {
                        ActivitySaveView(workoutManager: workoutManager)
                    }
                    
                    Spacer()
                }
                .navigationTitle("Workout Control")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    func lockScreen() {
        WKInterfaceDevice.current().enableWaterLock()
        workoutManager.liveTabSelection = LiveScreenTab.liveMetrics
    }
}

struct StopView_Previews: PreviewProvider {

    static var activityDataManager = ActivityDataManager()
    static var locationManager = LocationManager(activityDataManager: activityDataManager)
    static var settingsManager = SettingsManager()
    static var workoutManager = WorkoutManager(locationManager: locationManager, activityDataManager: activityDataManager,
        settingsManager: settingsManager)


    static var previews: some View {
        StopView(workoutManager: workoutManager)
    }
}
