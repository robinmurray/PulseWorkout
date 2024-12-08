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
    @ObservedObject var dataCache: DataCache
    var activityData: ActivityRecord
    
    @State var viewState = CGSize(width: 0, height: 50)
    
    enum NavigationTarget {
        case ActivitySaveView
    }
    
    init(navigationCoordinator: NavigationCoordinator,
         profile: Binding<ActivityProfile>,
         liveActivityManager: LiveActivityManager,
         dataCache: DataCache) {
        self.navigationCoordinator = navigationCoordinator
        self._profile = profile
        self.liveActivityManager = liveActivityManager
        self.dataCache = dataCache
        self.activityData = liveActivityManager.liveActivityRecord ??
        ActivityRecord(settingsManager: liveActivityManager.settingsManager)
        
    }
    
    func stopAndSave() {
        liveActivityManager.endWorkout()
        liveActivityManager.saveLiveActivityRecord()
        navigationCoordinator.selectedActivityRecord = liveActivityManager.liveActivityRecord ??
            ActivityRecord(settingsManager: liveActivityManager.settingsManager)
        
        navigationCoordinator.goToView(targetView: NavigationTarget.ActivitySaveView)
    }

    var body: some View {
        VStack {
            TimelineView(MetricsTimelineSchedule(
                from: liveActivityManager.liveActivityRecord?.startDateLocal ?? Date(),
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
                    
                    Section(header: HStack {
                        Image(systemName: heartRateIcon)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                        Text("Heart Rate")
                        Spacer()
                        }
                        .font(.title2)
                        .foregroundStyle(heartRateColor)
                    )
                    {
                        HStack {
                            Text(heartRateFormatter(heartRate: Double(liveActivityManager.heartRate ?? 0)))
                                .fontWeight(.bold)
                                .foregroundColor(HRDisplay[liveActivityManager.hrState]?.colour)
                                .frame(width: 140.0, height: 60.0)
                                .font(.system(size: 60))

                            Spacer()
                            VStack {

                                HStack {
                                    Image(systemName: maxIcon)
                                    Text(heartRateFormatter(heartRate: Double(activityData.averageHeartRate)))
                                }
 
                                HStack {
                                    Image(systemName: meanIcon)
                                    Text(heartRateFormatter(heartRate: activityData.maxHeartRate))
                                }

                            }
                        }
                        .foregroundStyle(heartRateColor)
                        .font(.title3)
                    }
 
                    
                    
                    Section(header: HStack {
                        Image(systemName: measureIcon)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                        Text("Distance")
                        Spacer()
                        }
                        .font(.title2)
                        .foregroundStyle(distanceColor)
                    )
                    {
                        HStack {
                            Text(distanceFormatter(distance: activityData.distanceMeters))
                                .font(.title)

                            Spacer()
                            VStack {
                                HStack {
                                    Image(systemName: ascentIcon)
                                    Text(distanceFormatter(distance: activityData.totalAscent ?? 0,
                                                           forceMeters: true))
                                }
                                HStack {
                                    Image(systemName: descentIcon)
                                    Text(distanceFormatter(distance: activityData.totalDescent ?? 0,
                                                           forceMeters: true))
                                }

                            }
                        }
                        .foregroundStyle(distanceColor)
                        .font(.title3)
                    }

                    
                    Section(header: HStack {
                        Image(systemName: speedIcon)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                        Text("Speed")
                        Spacer()
                        }
                        .font(.title2)
                        .foregroundStyle(speedColor)
                    )
                    {
                        HStack {
                            Text(speedFormatter(speed: activityData.speed ?? 0))
                                .font(.title)

                            Spacer()
                            VStack {
                                HStack {
                                    Image(systemName: maxIcon)
                                    Text(speedFormatter(speed: activityData.maxSpeed))
                                }
                                HStack {
                                    Image(systemName: meanIcon)
                                    Text(speedFormatter(speed: activityData.averageSpeed))
                                }

                            }
                        }
                        .foregroundStyle(speedColor)
                        .font(.title3)
                    }
                    

                    Section(header: HStack {
                        Image(systemName: powerIcon)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                        Text("Power")
                        Spacer()
                        }
                        .font(.title2)
                        .foregroundStyle(powerColor)
                    )
                    {
                        HStack {
                            Text(powerFormatter(watts: Double(activityData.watts ?? 0)))
                            .font(.title)
                            
                            Spacer()
                            VStack {
                                HStack {
                                    Image(systemName: maxIcon)
                                    Text(powerFormatter(watts: Double(activityData.maxPower)))

                                }
                                HStack {
                                    Image(systemName: meanIcon)
                                    Text(powerFormatter(watts: Double(activityData.averagePower)))

                                }

                            }

                        }
                        .foregroundStyle(powerColor)
                        .font(.title3)
                    }

                    Section(header: HStack {
                        Image(systemName: cadenceIcon)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                        Text("Cadence")
                        Spacer()
                        }
                        .font(.title2)
                        .foregroundStyle(cadenceColor)
                    )
                    {
                        HStack {

                            Text(String(activityData.cadence ?? 0))
                                .font(.title)

                            Spacer()

                            VStack {
                                HStack {
                                    Image(systemName: maxIcon)
                                    Text(String(activityData.maxCadence))
                                }
                                HStack {
                                    Image(systemName: meanIcon)
                                    Text(String(activityData.averageCadence))
                                }

                            }

                        }
                        .foregroundStyle(cadenceColor)
                        .font(.title3)
                    }

                }
                     
            }
//            .listStyle(.grouped)
//            .listStyle(.plain)

            Spacer()
            SwipeButton(swipeText: "Swipe to end",
                        perform: stopAndSave )
                .padding()


       
            BTDeviceBarView(liveActivityManager: liveActivityManager)
            

        }
        .navigationDestination(for: NavigationTarget.self) { pathValue in

            if pathValue == NavigationTarget.ActivitySaveView {

                ActivitySaveView(navigationCoordinator: navigationCoordinator,
                                 liveActivityManager: liveActivityManager,
                                 dataCache: dataCache)
                
            }
            
        }
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle(profile.name)
        .navigationBarBackButtonHidden()

    }

}
  

#Preview {

    @Previewable @State var newProfile: ActivityProfile = ProfileManager().newProfile()

    let navigationCoordinator = NavigationCoordinator()
    let settingsManager = SettingsManager()
    let locationManager = LocationManager(settingsManager: settingsManager)
    let dataCache = DataCache(settingsManager: settingsManager)
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         settingsManager: settingsManager,
                                                         dataCache: dataCache)

    LiveMetricsView(navigationCoordinator: navigationCoordinator,
                    profile: $newProfile,
                    liveActivityManager: liveActivityManager,
                    dataCache: dataCache)
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
