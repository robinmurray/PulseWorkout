//
//  StartView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//


import Foundation


import SwiftUI

let BTconnectedColour: [Bool: Color] =
[false: Color.gray,
 true: Color.blue]



struct StartView: View {

    @ObservedObject var profileData: ProfileData
//    @EnvironmentObject var workoutManager: WorkoutManager

    
    init(profileData: ProfileData) {
        self.profileData = profileData
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
            Text(profileData.workoutLocation.label + " " + profileData.workoutType.name)
                    .font(.system(size: 15))
                    .frame(height: 5)
                
            Spacer().frame(maxWidth: .infinity)
            
            VStack{
                Button(action: profileData.startWorkout) {
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

                 
            Spacer().frame(maxWidth: .infinity)
       
            HStack {
                Image(systemName:"heart.fill")
                    .foregroundColor(Color.red)

                Text("Profile: " + profileData.profileName)
                    .foregroundColor(Color.gray)
                    .font(.system(size: 15))
            }

                
                
            HStack {
                Image(systemName: "arrow.down.to.line.circle.fill")
                    .foregroundColor(loAlarmDisplay[profileData.loLimitAlarmActive]?.colour)
                    .frame(height: 20)
                    
                Text(loAlarmDisplay[profileData.loLimitAlarmActive]?.alarmLevelText ?? String(profileData.loLimitAlarm))
                    .foregroundColor(loAlarmDisplay[profileData.loLimitAlarmActive]?.colour)
                        .font(.system(size: 15))
                    
                Image(systemName: "arrow.up.to.line.circle.fill")
                        .foregroundColor(hiAlarmDisplay[profileData.hiLimitAlarmActive]?.colour)
                    .frame(height: 20)
                    
                Text(hiAlarmDisplay[profileData.hiLimitAlarmActive]?.alarmLevelText ?? String(profileData.hiLimitAlarm))
                    .foregroundColor(hiAlarmDisplay[profileData.hiLimitAlarmActive]?.colour)
                    .font(.system(size: 15))
                }

            Spacer().frame(maxWidth: .infinity)
       
            HStack {
                Image(systemName:"heart.fill")
                    .foregroundColor(BTconnectedColour[profileData.BTHRMConnected])
                Spacer().frame(maxWidth: .infinity)
                }
                
            }
            .padding()
            .navigationTitle("Start Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
}

struct StartView_Previews: PreviewProvider {
    static var profileData = ProfileData()

    static var previews: some View {
        StartView(profileData: profileData)
    }
}
