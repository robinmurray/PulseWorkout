//
//  ActiveView.swift
//  PulsePace Watch App
//
//  Created by Robin Murray on 18/12/2022.
//

import Foundation
import SwiftUI

enum ButtonState {
    case on
    case off
}

struct ButtonStyling  {
    var image: Image
    var colour: Color
}

struct HRStyling  {
    var HRText: String?
    var colour: Color
}

enum HRState {
    case inactive
    case normal
    case hiAlarm
    case loAlarm
}

struct AlarmStyling {
    var alarmLevelText: String?
    var colour: Color
}

enum AlarmActiveState {
    case inactive
    case active
}


struct ActiveView: View {
    //    @State var HR: Int = 180
    //    var profile = HRMonitor(name: "Race")
    
    @ObservedObject var profData: ProfileData
    
    let HRDisplay: [HRState: HRStyling] =
    [HRState.inactive: HRStyling(HRText: "___", colour: Color.gray),
     HRState.normal: HRStyling(colour: Color.green),
     HRState.hiAlarm: HRStyling(colour: Color.red),
     HRState.loAlarm: HRStyling(colour: Color.orange)]
    
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
    
    
    init(profileData: ProfileData) {
        self.profData = profileData
    }
    
    var body: some View {
        VStack {
             Divider()
                   .padding([.leading, .trailing], 50)
                   .frame(height: 20)
            
            HStack {
                lockImage[profData.HRMonitorActive]
                    .foregroundColor(lockColour[profData.lockScreen])
                    .scaleEffect(2)
                    .frame(height: 20)
                
                Divider()
                       .padding([.leading, .trailing], 50)

                
                Button(action: profData.startStopHRMonitor) {
                    playButtonStyle[profData.HRMonitorActive]!.image
                }
                .foregroundColor(playButtonStyle[profData.HRMonitorActive]?.colour)
                .frame(width: 20, height: 20)
                .scaleEffect(2)
                .background(Color.clear)

            }

            Text(HRDisplay[profData.hrState]?.HRText ?? String(profData.HR))
                .fontWeight(.bold)
                .foregroundColor(HRDisplay[profData.hrState]?.colour)
                .frame(height: 80)
                .padding()
                .font(.system(size: 80))

            
            Text("Profile: " + profData.profileName)
                .foregroundColor(Color.gray)
                .frame(height: 10)
                .font(.system(size: 15))


            HStack {
                    Image(systemName: "arrow.down.to.line.circle.fill")
                        .foregroundColor(loAlarmDisplay[profData.loLimitAlarmActive]?.colour)
                        .frame(height: 20)
                    
                    Text(loAlarmDisplay[profData.loLimitAlarmActive]?.alarmLevelText ?? String(profData.loLimitAlarm))
                        .foregroundColor(loAlarmDisplay[profData.loLimitAlarmActive]?.colour)
                        .font(.system(size: 15))
                    
                    Image(systemName: "arrow.up.to.line.circle.fill")
                        .foregroundColor(hiAlarmDisplay[profData.hiLimitAlarmActive]?.colour)
                        .frame(height: 20)
                    
                    Text(hiAlarmDisplay[profData.hiLimitAlarmActive]?.alarmLevelText ?? String(profData.hiLimitAlarm))
                        .foregroundColor(hiAlarmDisplay[profData.hiLimitAlarmActive]?.colour)
                        .font(.system(size: 15))
                }
            }
        .padding()
    }
}
    




struct ActiveView_Previews: PreviewProvider {
    
    static var profileData = ProfileData()

    static var previews: some View {
        ActiveView(profileData: profileData)
    }
}

