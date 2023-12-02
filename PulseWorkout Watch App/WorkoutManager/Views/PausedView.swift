//
//  PausedView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 23/12/2022.
//

import SwiftUI

struct PausedView: View {

    @ObservedObject var liveActivityManager: LiveActivityManager

    init(liveActivityManager: LiveActivityManager) {
        self.liveActivityManager = liveActivityManager
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

                        Button(action: liveActivityManager.resumeWorkout) {
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
                    Button(action: liveActivityManager.endWorkout) {
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
        liveActivityManager.resumeWorkout()
    }
}


struct PausedView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var activityDataManager = ActivityDataManager(settingsManager: settingsManager)
    static var locationManager = LocationManager(activityDataManager: activityDataManager, settingsManager: settingsManager)

    static var liveActivityManager = LiveActivityManager(locationManager: locationManager, activityDataManager: activityDataManager,
        settingsManager: settingsManager)
    
    static var previews: some View {
        PausedView(liveActivityManager: liveActivityManager)
    }
}
