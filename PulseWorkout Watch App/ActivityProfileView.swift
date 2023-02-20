//
//  ActivityProfileView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 15/02/2023.
//

import SwiftUI

struct ActivityProfileView: View {
    
    @ObservedObject var workoutManager: WorkoutManager
    var activityProfile: ActivityProfile
    
    let hiAlarmDisplay: [Bool: AlarmStyling] =
    [false: AlarmStyling(alarmLevelText: "___", colour: Color.gray),
     true: AlarmStyling(colour: Color.red)]
    
    let loAlarmDisplay: [Bool: AlarmStyling] =
    [false: AlarmStyling(alarmLevelText: "___", colour: Color.gray),
     true: AlarmStyling(colour: Color.orange)]

    
    init(workoutManager: WorkoutManager, activityProfile: ActivityProfile) {
        self.workoutManager = workoutManager
        self.activityProfile = activityProfile
    }

    func startWorkout() {
        workoutManager.startWorkout(activityProfile: activityProfile)
    }
    
    func editProfile() {
        workoutManager.startWorkout(activityProfile: activityProfile)

    }
    var body: some View {
        VStack {
            Text(activityProfile.name)
                .font(.system(size: 15))
                .fontWeight(.bold)
                .foregroundStyle(.yellow)

            HStack {
                VStack{
                    Button(action: editProfile) {
                    Image(systemName: "pencil.circle")
                        
                    }
                    .foregroundColor(Color.green)
                    .font(.title)
                    .frame(width: 40, height: 40)
                    .background(Color.clear)
                    .clipShape(Circle())
                    .buttonStyle(PlainButtonStyle())
                
                    Text("Edit")
                        .foregroundColor(Color.green)
                    
                }

                Spacer().frame(maxWidth: .infinity)

                VStack{
                    Button(action: startWorkout) {
                        Image(systemName: "play.circle")
                    }
                    .foregroundColor(Color.green)
                    .font(.title)
                    .frame(width: 40, height: 40)
                    .background(Color.clear)
                    .clipShape(Circle())
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("Start")
                        .foregroundColor(Color.green)
                    
                }
                
            }
            
            HStack {
                Image(systemName:"heart.fill")
                    .foregroundColor(Color.red)

                Image(systemName: "arrow.down.to.line.circle.fill")
                    .foregroundColor(loAlarmDisplay[activityProfile.loLimitAlarmActive]?.colour)
                    .frame(height: 20)
                
                Text(loAlarmDisplay[activityProfile.loLimitAlarmActive]?.alarmLevelText ?? String(activityProfile.loLimitAlarm))
                    .foregroundColor(loAlarmDisplay[activityProfile.loLimitAlarmActive]?.colour)
                    .font(.system(size: 15))
                
                Image(systemName: "arrow.up.to.line.circle.fill")
                    .foregroundColor(hiAlarmDisplay[activityProfile.hiLimitAlarmActive]?.colour)
                    .frame(height: 20)
                
                Text(hiAlarmDisplay[workoutManager.liveActivityProfile.hiLimitAlarmActive]?.alarmLevelText ?? String(activityProfile.hiLimitAlarm))
                    .foregroundColor(hiAlarmDisplay[activityProfile.hiLimitAlarmActive]?.colour)
                    .font(.system(size: 15))

            }
        }
    }
}

struct ActivityProfileView_Previews: PreviewProvider {

    static var workoutManager = WorkoutManager()
    static var activityProfiles = ActivityProfiles()

    static var previews: some View {
        ActivityProfileView(workoutManager: workoutManager, activityProfile: activityProfiles.getDefault())
    }

}
