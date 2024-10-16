//
//  LiveMetricsPausedView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 27/10/2023.
//

import SwiftUI

struct LiveMetricsPausedView: View {
    
    @ObservedObject var liveActivityManager: LiveActivityManager
    var activityData: ActivityRecord
    
    init(liveActivityManager: LiveActivityManager) {
        self.liveActivityManager = liveActivityManager
        self.activityData = liveActivityManager.liveActivityRecord ??
        ActivityRecord(settingsManager: liveActivityManager.settingsManager)
        
    }
    
    var body: some View {

            VStack {
                /*
                HStack {
                    Text("Paused")
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .foregroundStyle(Color.black)

                    Spacer()

                }
                .foregroundColor(Color.black)
                */

                 
                HStack {
                    TimelineView(MetricsTimelineSchedule(
                        from: liveActivityManager.locationManager.autoPauseStart ?? Date(),
                        isPaused: false,
                        lowFrequencyTimeInterval: 1.0,
                        highFrequencyTimeInterval: 1.0 / 2.0)
                        ) { context in
                        VStack {
                            HStack {
                                Image(systemName: "pause.fill")
                                    .fontWeight(.bold)
                                    .padding(.horizontal)
                                    .foregroundColor(Color.orange)
                                    .font(.system(size: 40))

                                Spacer()
                                
                                ElapsedTimeView(elapsedTime: liveActivityManager.currentPauseDurationAt(at: context.date),
                                                showSeconds: true,
                                                showSubseconds: false)
                                .foregroundStyle(Color.orange)
                                .font(.system(size: 20))

                            }
                            

                            
                            LiveMetricsCarouselView(
                                activityData: activityData,
                                contextDate: context.date)
                            .font(.system(size: 25))

                            HStack {
                                Spacer().frame(maxWidth: .infinity)
                                
                                Image(systemName: "heart.fill").foregroundColor(Color.red)
                                

                                
                                Text((liveActivityManager.heartRate ?? 0)
                                    .formatted(.number.precision(.fractionLength(0))))
                                    .fontWeight(.bold)
                                    .foregroundColor(HRDisplay[liveActivityManager.hrState]?.colour)
                                    .frame(width: 40.0, height: 30.0)
                                    .font(.system(size: 20))
                            }
                            
                            /*
                            HStack {
                                ElapsedTimeView(elapsedTime: liveActivityManager.elapsedTime(at: context.date),
                                                showSeconds: true,
                                                showSubseconds: context.cadence == .live)
                                .foregroundStyle(Color.white)
                                    .padding(.horizontal)
                                Spacer()
                            }
*/
                        }
                    }
                }


                Spacer().frame(maxWidth: .infinity)
           
                BTDeviceBarView(liveActivityManager: liveActivityManager)
        }


        
        }

}

struct LiveMetricsPausedView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache(settingsManager: settingsManager)
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         settingsManager: settingsManager,
                                                         dataCache: dataCache)

    static var previews: some View {

        LiveMetricsPausedView(liveActivityManager: liveActivityManager)

    }
}
