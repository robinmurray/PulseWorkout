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
//    @EnvironmentObject var workoutManager: WorkoutManager

    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }

    let hiAlarmDisplay: [Bool: AlarmStyling] =
    [false: AlarmStyling(alarmLevelText: "___", colour: Color.gray),
     true: AlarmStyling(colour: Color.red)]
    
    let loAlarmDisplay: [Bool: AlarmStyling] =
    [false: AlarmStyling(alarmLevelText: "___", colour: Color.gray),
     true: AlarmStyling(colour: Color.orange)]
    
    let lockColour: [Bool: Color] =
    [false: Color.clear,
     true: Color.blue]
    
    let lockImage: [Bool: Image] =
    [false: Image(systemName: "lock.open.trianglebadge.exclamationmark"),
     true: Image(systemName: "exclamationmark.lock.fill")]
    
    let soundImage: [Bool: Image] =
    [false: Image(systemName: "speaker.slash"),
     true: Image(systemName: "speaker.wave.2")]
    
    let hapticImage: [Bool: Image] =
    [false: Image(systemName: "waveform.slash"),
     true: Image(systemName: "waveform.path")]
    
    let repeatColour: [Bool: Color] =
    [false: Color.clear,
     true: Color.gray]


    
    var body: some View {
        VStack {
            Text(workoutManager.workoutLocation.label + " " + workoutManager.workoutType.name)
                    .font(.system(size: 15))
                    .frame(height: 5)
                
            Spacer().frame(maxWidth: .infinity)
            
            VStack{
                Button(action: workoutManager.startWorkout) {
                    Image(systemName: "play.circle")
                    }
                    .foregroundColor(Color.green)
                    .font(.title)
                    .frame(width: 40, height: 40)
                    .background(Color.clear)
                    .clipShape(Circle())
                
                Text("Start")
                    .foregroundColor(Color.green)

            }

                 
            HStack {
                Image(systemName:"heart.fill")
                    .foregroundColor(Color.red)

                Text("Profile: " + workoutManager.profileName)
                    .foregroundColor(Color.gray)
                    .font(.system(size: 15))
            }

                
                
            HStack {
                Image(systemName: "arrow.down.to.line.circle.fill")
                    .foregroundColor(loAlarmDisplay[workoutManager.loLimitAlarmActive]?.colour)
                    .frame(height: 20)
                    
                Text(loAlarmDisplay[workoutManager.loLimitAlarmActive]?.alarmLevelText ?? String(workoutManager.loLimitAlarm))
                    .foregroundColor(loAlarmDisplay[workoutManager.loLimitAlarmActive]?.colour)
                        .font(.system(size: 15))
                    
                Image(systemName: "arrow.up.to.line.circle.fill")
                        .foregroundColor(hiAlarmDisplay[workoutManager.hiLimitAlarmActive]?.colour)
                    .frame(height: 20)
                    
                Text(hiAlarmDisplay[workoutManager.hiLimitAlarmActive]?.alarmLevelText ?? String(workoutManager.hiLimitAlarm))
                    .foregroundColor(hiAlarmDisplay[workoutManager.hiLimitAlarmActive]?.colour)
                    .font(.system(size: 15))
                }

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
