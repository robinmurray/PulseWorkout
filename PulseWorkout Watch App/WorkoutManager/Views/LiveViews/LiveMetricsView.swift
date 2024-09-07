//
//  LiveMetricsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import SwiftUI
import HealthKit


struct GetHeightModifier: ViewModifier {
    @Binding var height: CGFloat

    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo -> Color in
                DispatchQueue.main.async {
                    height = geo.size.height
                }
                return Color.clear
            }
        )
    }
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

let speedIcon = "speedometer"
let distanceIcon = "arrowshape.forward"
let ascentIcon = "arrow.up.right.circle"
let cadenceIcon = "arrow.clockwise.circle"
let powerIcon = "bolt"
let heartRateIcon = "heart.fill"
let meanIcon = "arrow.up.and.line.horizontal.and.arrow.down"

struct LiveMetricsView: View {
    
    @ObservedObject var liveActivityManager: LiveActivityManager
    var activityData: ActivityRecord

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

    
    init(liveActivityManager: LiveActivityManager) {
        self.liveActivityManager = liveActivityManager
        self.activityData = liveActivityManager.liveActivityRecord ??
        ActivityRecord(settingsManager: liveActivityManager.settingsManager)
        
    }
    

    var body: some View {

        
        TimelineView(MetricsTimelineSchedule(
            from: liveActivityManager.builder?.startDate ?? Date(),
            isPaused: liveActivityManager.session?.state == .paused,
            lowFrequencyTimeInterval: 10.0,
            highFrequencyTimeInterval: 1.0 / 20.0)
        ) { context in
            
            switch context.cadence {
            case .live:

                VStack {
                    HStack {

                                ElapsedTimeView(elapsedTime: liveActivityManager.movingTime(at: context.date),
                                                showSeconds: true,
                                                showSubseconds: context.cadence == .live)
                                    .foregroundStyle(.yellow)

                        Spacer()
                    }

                    LiveMetricsCarouselView(
                        activityData: activityData,
                        contextDate: context.date)

                    Spacer()

                    ZStack {
                        HStack {
                            Image(systemName: "heart.fill").foregroundColor(Color.red)
                            
                            Spacer().frame(maxWidth: .infinity)
                            
                            Text((liveActivityManager.heartRate ?? 0)
                                .formatted(.number.precision(.fractionLength(0))))
                                .fontWeight(.bold)
                                .foregroundColor(HRDisplay[liveActivityManager.hrState]?.colour)
                                .frame(width: 140.0, height: 60.0)
                                .font(.system(size: 60))
                        }
                        
                        if (liveActivityManager.locationManager.isPaused == true) &&
                            (liveActivityManager.currentPauseDuration() > 0) {
                            LiveMetricsPausedView(liveActivityManager: liveActivityManager)

                        }

                        
                    }

                    
                    Spacer().frame(maxWidth: .infinity)
               
                    BTDeviceBarView(liveActivityManager: liveActivityManager)
                }
                
                
            default:
                LiveAlwaysOnView(liveActivityManager: liveActivityManager,
                                 contextDate: context.date)
                
            }
        }
        .padding(.horizontal)
        
    }

}
    

struct LiveMetricsView_Previews: PreviewProvider {
    
    static var activityProfile = ActivityProfiles()
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache()
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager, settingsManager: settingsManager,
        dataCache: dataCache)

    
    static var previews: some View {
        LiveMetricsView(liveActivityManager: liveActivityManager)
    }
}


struct MetricsTimelineSchedule: TimelineSchedule {
    var startDate: Date
    var isPaused: Bool
    var lowFrequencyTimeInterval: TimeInterval
    var highFrequencyTimeInterval: TimeInterval

    init(from startDate: Date,
         isPaused: Bool,
         lowFrequencyTimeInterval: TimeInterval,
         highFrequencyTimeInterval: TimeInterval) {
        self.startDate = startDate
        self.isPaused = isPaused
        self.lowFrequencyTimeInterval = lowFrequencyTimeInterval
        self.highFrequencyTimeInterval = highFrequencyTimeInterval
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        var baseSchedule = PeriodicTimelineSchedule(from: self.startDate,
                                                    by: (mode == .lowFrequency ? lowFrequencyTimeInterval : highFrequencyTimeInterval))
            .entries(from: startDate, mode: mode)
        
        return AnyIterator<Date> {
            guard !isPaused else { return nil }
            return baseSchedule.next()
        }
    }
}
