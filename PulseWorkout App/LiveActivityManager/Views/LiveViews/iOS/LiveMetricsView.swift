//
//  LiveMetricsView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 18/11/2024.
//

import SwiftUI

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
    

    var body: some View {
        VStack {
            TimelineView(MetricsTimelineSchedule(
                from: liveActivityManager.liveActivityRecord?.startDateLocal ?? Date(),
                isPaused: false,
                lowFrequencyTimeInterval: 10.0,
                highFrequencyTimeInterval: 1.0 / 20.0)
            ) { context in
                
                VStack {
                    
                    Text(profile.name)
                    
                    HStack {
                        
                        ElapsedTimeView(elapsedTime: liveActivityManager.movingTime(at: Date()),
                                        showSeconds: true,
                                        showSubseconds: true)
                        .foregroundStyle(.yellow)
                        
                        Spacer()
                    }
                    Spacer()
                    
                    
                }
            }
            
            Button {
                liveActivityManager.endWorkout()
                liveActivityManager.saveLiveActivityRecord()
                navigationCoordinator.selectedActivityRecord = liveActivityManager.liveActivityRecord ??
                    ActivityRecord(settingsManager: liveActivityManager.settingsManager)
                
                navigationCoordinator.goToView(targetView: NavigationTarget.ActivitySaveView)

            } label: {
                VStack{
                    Image(systemName: "stop.circle")
                        .foregroundColor(Color.red)
                        .font(.title2)
                        .frame(width: 80, height: 80)
                        .background(Color.clear)
                        .clipShape(Circle())
                        .buttonStyle(PlainButtonStyle())
                    
                    Text("Stop")
                        .foregroundColor(Color.red)
                }
                
            }
            .tint(Color.red)
            .buttonStyle(BorderlessButtonStyle())
            Spacer()
            
            HStack{
                
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.red)
                        .frame(width: 100, height: 100)
                        .offset(x: viewState.width)
                        .gesture(
                            DragGesture().onChanged { value in
                                viewState = value.translation
                            }
                                .onEnded { value in
                                    withAnimation(.spring()) {
                                        viewState = .zero
                                    }
                                }
                        )
                    
                    Image(systemName: "chevron.forward.circle")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .offset(x: viewState.width)
                        .foregroundColor(Color.white)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    viewState = value.translation
                                    print("viewState : \(viewState)")
                                
                                }
                                .onEnded { value in
                                    withAnimation(.spring()) {
                                        viewState = .zero

                                        if value.translation.width > 100 {
                                            liveActivityManager.endWorkout()
                                            liveActivityManager.saveLiveActivityRecord()
                                            
                                            navigationCoordinator.goToView(targetView: NavigationTarget.ActivitySaveView)
                                        }
                                    }
                                }
                                
                        )
                    
                }
            }
            
            Spacer()
       
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
