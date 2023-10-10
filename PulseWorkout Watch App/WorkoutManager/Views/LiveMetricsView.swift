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
    @ObservedObject var activityData: ActivityRecord

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
        self.activityData = workoutManager.activityDataManager.liveActivityRecord!
    }
    
    var body: some View {

        VStack {
            HStack {
                VStack {
                    HStack {
 //                       Image(systemName: "timer")
 //                           .foregroundColor(Color.yellow)
                        TimelineView(MetricsTimelineSchedule(from: workoutManager.builder?.startDate ?? Date(),
                                                             isPaused: workoutManager.session?.state == .paused)) { context in
                            
                            ElapsedTimeView(elapsedTime: workoutManager.builder?.elapsedTime(at: context.date) ?? 0, showSubseconds: context.cadence == .live)
                                .foregroundStyle(.yellow)
                            }
                        Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "arrowshape.forward")
                                .foregroundColor(Color.yellow)
                            Text(distanceFormatter(distance: activityData.distanceMeters))
        //                        .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.trailing, 8)
                                    .foregroundColor(Color.yellow)
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "arrow.up.right.circle")
                                .foregroundColor(Color.yellow)
                            Text(distanceFormatter(distance: activityData.totalAscent ?? 0))
        //                        .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.trailing, 8)
                                    .foregroundColor(Color.yellow)
                            Spacer()
                        }
                }
                
                
                Spacer()
                
                VStack {
                    HStack {
                        Image(systemName: "speedometer")
                            .foregroundColor(Color.yellow)
                        Text(speedFormatter(speed: activityData.speed ?? 0))
                            .foregroundColor(Color.yellow)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "bolt")
                            .foregroundColor(Color.yellow)
                        Text(String(activityData.watts ?? 0) + " w")
                            .foregroundColor(Color.yellow)
                        Spacer()
                    }

                    HStack {
                        Image(systemName: "arrow.clockwise.circle")
                            .foregroundColor(Color.yellow)
                        Text(String(activityData.cadence ?? 0))
                            .foregroundColor(Color.yellow)
                        Spacer()
                    }
                }
    
            }
            

 

            Spacer()

            HStack {
                    Image(systemName: "heart.fill").foregroundColor(Color.red)
                    Spacer().frame(maxWidth: .infinity)
                    Text((workoutManager.heartRate ?? 0)
                        .formatted(.number.precision(.fractionLength(0))))
                    .fontWeight(.bold)
                    .foregroundColor(HRDisplay[workoutManager.hrState]?.colour)
                    .frame(width: 140.0, height: 60.0)
                    .font(.system(size: 60))
                }

/*
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
*/
            Spacer().frame(maxWidth: .infinity)
       
            BTDeviceBarView(workoutManager: workoutManager)

        }
        .padding(.horizontal)

        }


}
    

struct LiveMetricsView_Previews: PreviewProvider {
    
    static var activityDataManager = ActivityDataManager()
    static var locationManager = LocationManager(activityDataManager: activityDataManager)
    static var settingsManager = SettingsManager()
    static var workoutManager = WorkoutManager(locationManager: locationManager, activityDataManager: activityDataManager,
        settingsManager: settingsManager)
    
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
