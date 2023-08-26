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
    
    @ObservedObject var workoutManager: WorkoutManager

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
    
    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }
    
    var body: some View {

        VStack {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(Color.yellow)
                TimelineView(MetricsTimelineSchedule(from: workoutManager.builder?.startDate ?? Date(),
                                                     isPaused: workoutManager.session?.state == .paused)) { context in
                    
                    ElapsedTimeView(elapsedTime: workoutManager.builder?.elapsedTime(at: context.date) ?? 0, showSubseconds: context.cadence == .live)
                        .foregroundStyle(.yellow)
                }
                Spacer()
                Image(systemName: "bolt")
                    .foregroundColor(Color.yellow)
                Text(String(workoutManager.cyclingPower))
                    .foregroundColor(Color.yellow)
            }
            HStack {
                HStack {
                    Image(systemName: "figure.walk.motion")
                        .foregroundColor(Color.yellow)
                    Text(distanceFormatter(distance: workoutManager.activityRecord.distance))
//                        .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 8)
                            .foregroundColor(Color.yellow)
                }

                Spacer()
                HStack {
                    Image(systemName: "speedometer")
                        .foregroundColor(Color.yellow)
                    Text(String(workoutManager.cyclingCadence))
                        .foregroundColor(Color.yellow)
                }

            }

            Spacer()

            HStack {
                    Image(systemName: "heart.fill").foregroundColor(Color.red)
                    Spacer().frame(maxWidth: .infinity)
                    Text(workoutManager.heartRate
                        .formatted(.number.precision(.fractionLength(0))))
                    .fontWeight(.bold)
                    .foregroundColor(HRDisplay[workoutManager.hrState]?.colour)
                    .frame(width: 140.0, height: 60.0)
                    .font(.system(size: 60))
                }


            HStack {
                    Image(systemName: "arrow.down.to.line.circle.fill")
                    .foregroundColor(loAlarmDisplay[workoutManager.liveActivityProfile!.loLimitAlarmActive]?.colour)
                        .frame(height: 20)
                    
                Text(loAlarmDisplay[workoutManager.liveActivityProfile!.loLimitAlarmActive]?.alarmLevelText ?? String(workoutManager.liveActivityProfile!.loLimitAlarm ))
                        .foregroundColor(loAlarmDisplay[workoutManager.liveActivityProfile!.loLimitAlarmActive]?.colour)
                        .font(.system(size: 15))
                    
                    Image(systemName: "arrow.up.to.line.circle.fill")
                        .foregroundColor(hiAlarmDisplay[workoutManager.liveActivityProfile!.hiLimitAlarmActive]?.colour)
                        .frame(height: 20)
                    
                    Text(hiAlarmDisplay[workoutManager.liveActivityProfile!.hiLimitAlarmActive]?.alarmLevelText ?? String(workoutManager.liveActivityProfile!.hiLimitAlarm))
                        .foregroundColor(hiAlarmDisplay[workoutManager.liveActivityProfile!.hiLimitAlarmActive]?.colour)
                        .font(.system(size: 15))
                }

            Spacer().frame(maxWidth: .infinity)
       
            BTDeviceBarView(workoutManager: workoutManager)

        }
        .padding(.horizontal)

        }
//        .padding(.horizontal)
//        .navigationTitle(workoutManager.liveActivityProfile.name)
//        .navigationBarTitleDisplayMode(.inline)

}
    

struct LiveMetricsView_Previews: PreviewProvider {
    
    static var workoutManager = WorkoutManager()

    static var previews: some View {
        LiveMetricsView(workoutManager: workoutManager)
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
