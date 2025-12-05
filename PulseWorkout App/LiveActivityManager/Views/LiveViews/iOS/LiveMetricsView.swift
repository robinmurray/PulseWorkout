//
//  LiveMetricsView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 18/11/2024.
//

import SwiftUI

struct HRStyling  {
    var HRText: String?
    var colour: Color
}

let HRDisplay: [HRState: HRStyling] =
[HRState.inactive: HRStyling(HRText: "___", colour: Color.gray),
 HRState.normal: HRStyling(colour: Color.green),
 HRState.hiAlarm: HRStyling(colour: Color.red),
 HRState.loAlarm: HRStyling(colour: Color.orange)]

struct LiveMetricsView: View {

    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @Binding var profile: ActivityProfile
    @ObservedObject var liveActivityManager: LiveActivityManager
    var activityData: ActivityRecord
    
    @State var viewState = CGSize(width: 0, height: 50)
    
    enum NavigationTarget {
        case ActivitySaveView
    }
    
    init(navigationCoordinator: NavigationCoordinator,
         profile: Binding<ActivityProfile>,
         liveActivityManager: LiveActivityManager) {
        self.navigationCoordinator = navigationCoordinator
        self._profile = profile
        self.liveActivityManager = liveActivityManager
        self.activityData = liveActivityManager.liveActivityRecord ??
        ActivityRecord()
        
    }
    
    func stopAndSave() {
        liveActivityManager.endWorkout()
        liveActivityManager.saveLiveActivityRecord()
        navigationCoordinator.selectedActivityRecord = liveActivityManager.liveActivityRecord ??
            ActivityRecord()
        
        navigationCoordinator.goToView(targetView: NavigationTarget.ActivitySaveView)
    }

    var body: some View {
        VStack {
            TimelineView(MetricsTimelineSchedule(
                from: liveActivityManager.liveActivityRecord?.startDate ?? Date(),
                isPaused: false,
                lowFrequencyTimeInterval: 10.0,
                highFrequencyTimeInterval: 1.0 / 20.0)
            ) { context in

                HStack {
                    
                    HStack{
                        Image(systemName: movingTimeIcon)
                        ElapsedTimeView(elapsedTime: liveActivityManager.movingTime(at: Date()),
                                        showSeconds: true,
                                        showSubseconds: context.cadence == .live)
                    }
                    .foregroundStyle(.green)
                    .font(.title)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "pause.fill")
                        ElapsedTimeView(elapsedTime: liveActivityManager.pausedTime(at: Date()),
                                        showSeconds: true,
                                        showSubseconds: context.cadence == .live)

                    }
                    .foregroundStyle(.orange)


                }
                

                HStack {

                    
                    Spacer()

                    HStack {
                        Image(systemName: "timer")
                        ElapsedTimeView(elapsedTime: liveActivityManager.elapsedTime(at: Date()),
                                        showSeconds: true,
                                        showSubseconds: context.cadence == .live)

                    }
                    .foregroundStyle(.yellow)
                }

                
                List {
                    
                    Group {
                        VStack {
                            HStack {
                                Image(systemName: heartRateIcon)
                                    .font(.title)
                                Text("Heart Rate")
                                Spacer()
                            }
                            .foregroundStyle(heartRateColor)
                            
                            HStack {
                                Text(heartRateFormatter(heartRate: Double(liveActivityManager.heartRate ?? 100)))
                                    .fontWeight(.bold)
                                    .foregroundColor(HRDisplay[liveActivityManager.hrState]?.colour)
                                //.frame(width: 160.0, height: 60.0)
                                    .frame(width: 240, alignment: .trailing)
                                    .font(.system(size: 60))
                                
                                Spacer()
                                
                                VStack {
                                    Image(systemName: maxIcon)
                                    Image(systemName: meanIcon)
                                }
                                
                                VStack {
                                    
                                    Text(heartRateFormatter(heartRate: Double(activityData.averageHeartRate)))
                                        .frame(width: 80, alignment: .trailing)
                                    Text(heartRateFormatter(heartRate: activityData.maxHeartRate))
                                        .frame(width: 80, alignment: .trailing)
                                    
                                }
                            }
                        }
                        .foregroundStyle(heartRateColor)
                        .font(.title3)
                    }
                    
                    
                    Group {
                        VStack {
                            HStack {
                                Image(systemName: measureIcon)
                                    .font(.title)
                                Text("Distance")
                                Spacer()
                            }
                            
                            HStack {
                                Text(distanceFormatter(distance: activityData.distanceMeters))
                                    .fontWeight(.bold)
                                    .frame(width: 240, alignment: .trailing)
                                    .font(.system(size: 60))
                                
                                Spacer()
                                
                                VStack {
                                    Image(systemName: ascentIcon)
                                    Image(systemName: descentIcon)
                                }
                                
                                VStack {
                                    
                                    Text(distanceFormatter(distance: activityData.totalAscent ?? 0,
                                                           forceMeters: true))
                                    .frame(width: 80, alignment: .trailing)
                                    Text(distanceFormatter(distance: activityData.totalDescent ?? 5000,
                                                           forceMeters: true))
                                    .frame(width: 80, alignment: .trailing)
                                    
                                }
                            }
                        }
                        .foregroundStyle(distanceColor)
                        .font(.title3)
                        
                    }
                    
                    
                    
                    Group {
                        VStack {
                            HStack {
                                Image(systemName: speedIcon)
                                    .font(.title)
                                Text("Speed")
                                Spacer()
                            }
                            
                            HStack {
                                
                                Text(speedFormatter(speed: activityData.speed ?? 0))
                                    .fontWeight(.bold)
                                    .frame(width: 240, alignment: .trailing)
                                    .font(.system(size: 60))
                                
                                
                                Spacer()
                                
                                VStack {
                                    Image(systemName: maxIcon)
                                    Image(systemName: meanIcon)
                                }
                                
                                VStack {
                                    
                                    Text(speedFormatter(speed: activityData.maxSpeed))
                                        .frame(width: 80, alignment: .trailing)
                                    Text(speedFormatter(speed: activityData.averageSpeed))
                                        .frame(width: 80, alignment: .trailing)
                                    
                                }
                            }
                        }
                        .foregroundStyle(speedColor)
                        .font(.title3)
                    }
                    
                    
                    Group {
                        VStack {
                            HStack {
                                Image(systemName: powerIcon)
                                    .font(.title)
                                Text("Power")
                                Spacer()
                            }
                            
                            HStack {
                                
                                Text(powerFormatter(watts: Double(activityData.watts ?? 0)))
                                    .fontWeight(.bold)
                                    .frame(width: 240, alignment: .trailing)
                                    .font(.system(size: 60))
                                
                                
                                Spacer()
                                
                                VStack {
                                    Image(systemName: maxIcon)
                                    Image(systemName: meanIcon)
                                }
                                
                                VStack {
                                    
                                    Text(powerFormatter(watts: Double(activityData.maxPower)))
                                        .frame(width: 80, alignment: .trailing)
                                    Text(powerFormatter(watts: Double(activityData.averagePower)))
                                        .frame(width: 80, alignment: .trailing)
                                    
                                }
                            }
                            
                        }
                        .foregroundStyle(powerColor)
                        .font(.title3)
                    }
                    
                    
                    Group {
                        VStack {
                            HStack {
                                Image(systemName: cadenceIcon)
                                    .font(.title)
                                Text("Cadence")
                                Spacer()
                            }
                            
                            HStack {
                                
                                Text(String(activityData.cadence ?? 0))
                                    .fontWeight(.bold)
                                    .frame(width: 240, alignment: .trailing)
                                    .font(.system(size: 60))
                                
                                
                                Spacer()
                                
                                VStack {
                                    Image(systemName: maxIcon)
                                    Image(systemName: meanIcon)
                                }
                                
                                VStack {
                                    
                                    Text(String(activityData.maxCadence))
                                        .frame(width: 80, alignment: .trailing)
                                    Text(String(activityData.averageCadence))
                                        .frame(width: 80, alignment: .trailing)
                                    
                                }
                            }
                            
                        }
                        .foregroundStyle(cadenceColor)
                        .font(.title3)
                    }
                }
            }
            .listStyle(.grouped)

            

            
            Spacer()
            SwipeButton(swipeText: "Swipe to end",
                        perform: stopAndSave )
                .padding()


       
            BTDeviceBarView(liveActivityManager: liveActivityManager)
            

        }
        .navigationDestination(for: NavigationTarget.self) { pathValue in

            if pathValue == NavigationTarget.ActivitySaveView {

                ActivitySaveView(navigationCoordinator: navigationCoordinator,
                                 liveActivityManager: liveActivityManager)
                
            }
            
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle(profile.name)
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)

    }

}
  

#Preview {

    @Previewable @State var newProfile: ActivityProfile = ProfileManager().newProfile()

    let navigationCoordinator = NavigationCoordinator()
    let locationManager = LocationManager()
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                  bluetoothManager: bluetoothManager)

    LiveMetricsView(navigationCoordinator: navigationCoordinator,
                    profile: $newProfile,
                    liveActivityManager: liveActivityManager)
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
