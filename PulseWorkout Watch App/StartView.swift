//
//  StartView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//


import Foundation


import SwiftUI

struct StartView: View {

    @ObservedObject var profileData: ProfileData
    
    
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
    
    let playButtonStyle: [Bool: ButtonStyling] =
    [true: ButtonStyling(image: Image(systemName: "stop.circle"), colour: Color.red),
     false: ButtonStyling(image: Image(systemName: "play.circle"), colour: Color.green)]

    
    var body: some View {
        VStack {
            Button(action: profileData.startStopHRMonitor) {
                playButtonStyle[profileData.HRMonitorActive]!.image
            }
            .foregroundColor(playButtonStyle[profileData.HRMonitorActive]?.colour)
//            .frame(width: 20, height: 20)
            .scaleEffect(3)
            .background(Color.clear)
            .padding()

            Text("Profile: " + profileData.profileName)
                .foregroundColor(Color.gray)
                .frame(height: 10)
                .font(.system(size: 15))


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
                HStack {
                    
                    soundImage[profileData.playSound]
                        .foregroundColor(Color.gray)
                    hapticImage[profileData.playHaptic]
                        .foregroundColor(Color.gray)
                    
                    Image(systemName: "repeat")
                        .foregroundColor(repeatColour[profileData.constantRepeat])
                }
                
            }
        .padding()
    }

}

struct StartView_Previews: PreviewProvider {
    static var profileData = ProfileData()

    static var previews: some View {
        StartView(profileData: profileData)
    }
}
