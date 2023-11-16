//
//  LiveMetricsView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import SwiftUI


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


struct LiveMetricsView: View {
    
    @ObservedObject var workoutManager: WorkoutManager
    var activityData: ActivityRecord

    // to manage fixed height scrolling view
    @State private var scrollStackheight: CGFloat = 0

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
        self.activityData = workoutManager.activityDataManager.liveActivityRecord ??
            workoutManager.activityDataManager.dummyActivityRecord
        
    }
    
    func scrollPosition(scrollDate: Date, scrollInterval: Int, scrollItems: Int) -> Int {
        
        let seconds = Calendar.current.component(.second, from: scrollDate)
        let scrollCount: Int = seconds / scrollInterval
        let scrollPos: Int = scrollCount % scrollItems
        
        return scrollPos
    }

    var body: some View {
        
        VStack {
            
            HStack {
                VStack {
                    
                    HStack {

                        TimelineView(MetricsTimelineSchedule(from: workoutManager.builder?.startDate ?? Date(),
                                                                 isPaused: workoutManager.session?.state == .paused)) { context in
                                
                                ElapsedTimeView(elapsedTime: workoutManager.movingTime(at: context.date), showSubseconds: context.cadence == .live)
                                    .foregroundStyle(.yellow)
                            }
                            
                        Spacer()
                    }

                    TimelineView(.periodic(from: Date(), by: 1)) { context in
                        
                        ScrollView {
                            VStack {

                                switch scrollPosition(scrollDate: context.date,
                                                      scrollInterval: 2,
                                                      scrollItems: 4) {
                                case 0:
                                    LiveMetricCarouselItem(
                                        metric1: (image: "arrowshape.forward",
                                                  text: distanceFormatter(distance: activityData.distanceMeters)),
                                        metric2: (image: "arrow.up.right.circle",
                                                  text: distanceFormatter(distance: activityData.totalAscent ?? 0,
                                                                              forceMeters: true))
                                    )
                                        .modifier(GetHeightModifier(height: $scrollStackheight))

                                        
                                case 1:
                                    // Speed and Average Speed
                                    LiveMetricCarouselItem(
                                        metric1: (image: "speedometer",
                                                  text: speedFormatter(speed: activityData.speed ?? 0)),
                                        metric2: (image: "arrow.up.and.line.horizontal.and.arrow.down",
                                                  text: speedFormatter(speed: activityData.averageSpeed))
                                    )
                                        .modifier(GetHeightModifier(height: $scrollStackheight))
 
                                case 2:
                                    // Power and Average Power
                                    LiveMetricCarouselItem(
                                        metric1: (image: "bolt",
                                                  text: String(activityData.watts ?? 0) + " w"),
                                        metric2: (image: "arrow.up.and.line.horizontal.and.arrow.down",
                                                  text: String(activityData.averagePower ) + " w")
                                    )
                                    .modifier(GetHeightModifier(height: $scrollStackheight))

                                        
                                case 3:
                                    // Cadence and Average Cadence
                                    LiveMetricCarouselItem(
                                        metric1: (image: "arrow.clockwise.circle",
                                                  text: String(activityData.cadence ?? 0)),
                                        metric2: (image: "arrow.up.and.line.horizontal.and.arrow.down",
                                                  text: String(activityData.averageCadence))
                                    )
                                    .modifier(GetHeightModifier(height: $scrollStackheight))
                                       
                                default:
                                    LiveMetricCarouselItem(
                                        metric1: (image: "arrowshape.forward",
                                                  text: distanceFormatter(distance: activityData.distanceMeters)),
                                        metric2: (image: "arrow.up.right.circle",
                                                  text: distanceFormatter(distance: activityData.totalAscent ?? 0,
                                                                              forceMeters: true))
                                    )
                                        .modifier(GetHeightModifier(height: $scrollStackheight))
                                        
                                }
                                    
                             }
                            
                        }
                        .frame(height: scrollStackheight)
 
                    }

                }

            }

            Spacer()

            ZStack {
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
                
                if (workoutManager.locationManager.isPaused == true) &&
                    (workoutManager.currentPauseDuration() > 0) {
                    LiveMetricsPausedView(workoutManager: workoutManager)

                }

                
            }


            Spacer().frame(maxWidth: .infinity)
       
            
            BTDeviceBarView(workoutManager: workoutManager)

        }
        .padding(.horizontal)

        }


}
    

struct LiveMetricsView_Previews: PreviewProvider {
    
    static var activityProfile = ActivityProfiles()
    static var settingsManager = SettingsManager()
    static var activityDataManager = ActivityDataManager(settingsManager: settingsManager)
    static var locationManager = LocationManager(activityDataManager: activityDataManager, settingsManager: settingsManager)

    static var workoutManager = WorkoutManager(locationManager: locationManager, activityDataManager: activityDataManager,
        settingsManager: settingsManager)

    
    static var previews: some View {
        LiveMetricsView(workoutManager: workoutManager)
    }
}


struct MetricsTimelineSchedule: TimelineSchedule {
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
