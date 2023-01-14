//
//  LiveMetricsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import SwiftUI


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


struct LiveMetricsView: View {
    
    @ObservedObject var profileData: ProfileData

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
    
    
    init(profileData: ProfileData) {
        self.profileData = profileData
    }
    
    var body: some View {
        VStack {

            TimelineView(MetricsTimelineSchedule(from: profileData.builder?.startDate ?? Date(),
                                                 isPaused: profileData.session?.state == .paused)) { context in
                
                ElapsedTimeView(elapsedTime: profileData.builder?.elapsedTime(at: context.date) ?? 0, showSubseconds: context.cadence == .live)
                    .foregroundStyle(.yellow)
            }
                
            

 //           Text(HRDisplay[profileData.hrState]?.HRText ?? String(profileData.HR))
//                .fontWeight(.bold)
//                .foregroundColor(HRDisplay[profileData.hrState]?.colour)
//                .frame(height: 80)
//                .padding()
//                .font(.system(size: 80))

            HStack {
                    Image(systemName: "heart.fill").foregroundColor(Color.red)
                    Spacer().frame(maxWidth: .infinity)
                    Text(profileData.heartRate
                        .formatted(.number.precision(.fractionLength(0))))
                    .fontWeight(.bold)
                    .foregroundColor(HRDisplay[profileData.hrState]?.colour)
//                    .multilineTextAlignment(.trailing)
                    .frame(width: 140.0, height: 80)
 //                   .padding()
                    .font(.system(size: 80))
                }

            HStack {
                Text("Dist.").foregroundColor(Color.yellow)
                Spacer().frame(maxWidth: .infinity)
                Text(distanceFormatter(distance: profileData.summaryMetrics.distance))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 8)
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
            }
        .padding()
    }
    
}
    
func distanceFormatter (distance: Double) -> String {
    var unit = UnitLength.meters
    var displayDistance: Double = distance.rounded()
    if distance > 1000 {
        unit = UnitLength.kilometers
        displayDistance = distance / 1000
        if displayDistance > 100 {
            displayDistance = (displayDistance * 10).rounded() / 10
        } else if displayDistance > 10 {
            displayDistance = (displayDistance * 100).rounded() / 100
        } else {
            displayDistance = (displayDistance * 10).rounded() / 10
        }

    }
    
    return  Measurement(value: displayDistance,
                       unit: unit)
    .formatted(.measurement(width: .abbreviated,
                            usage: .asProvided
                           )
    )

}




struct LiveMetricsView_Previews: PreviewProvider {
    
    static var profileData = ProfileData()

    static var previews: some View {
        LiveMetricsView(profileData: profileData)
    }
}


private struct MetricsTimelineSchedule: TimelineSchedule {
    var startDate: Date
    var isPaused: Bool

    init(from startDate: Date, isPaused: Bool) {
        self.startDate = startDate
        self.isPaused = isPaused
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        var baseSchedule = PeriodicTimelineSchedule(from: self.startDate,
                                                    by: (mode == .lowFrequency ? 1.0 : 1.0 / 30.0))
            .entries(from: startDate, mode: mode)
        
        return AnyIterator<Date> {
            guard !isPaused else { return nil }
            return baseSchedule.next()
        }
    }
}
