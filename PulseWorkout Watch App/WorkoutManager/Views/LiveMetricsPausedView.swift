//
//  LiveMetricsPausedView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 27/10/2023.
//

import SwiftUI

struct LiveMetricsPausedView: View {
    
    @ObservedObject var workoutManager: WorkoutManager

    var body: some View {
        ZStack {
            Image(systemName: "pause.fill")
                .fontWeight(.bold)
                .padding(.horizontal)
                .foregroundColor(Color.orange)
                .font(.system(size: 50))

            VStack {
                HStack {
                    Text("Paused")
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .foregroundStyle(Color.black)

                    Spacer()

                }
                .foregroundColor(Color.black)
                

                 
                HStack {
                    
                    TimelineView(MetricsTimelineSchedule(from: workoutManager.locationManager.autoPauseStart ?? Date(),
                                                         isPaused: false)) { context in
                        VStack {
                            HStack {
                                ElapsedTimeView(elapsedTime: workoutManager.currentPauseDurationAt(at: context.date),
                                                showSubseconds: context.cadence == .live)
                                    .foregroundStyle(.black)
                                    .padding(.horizontal)
                                Spacer()
                            }

                            HStack {
                                ElapsedTimeView(elapsedTime: workoutManager.elapsedTime(at: context.date),
                                                showSubseconds: context.cadence == .live)
                                .foregroundStyle(Color.white)
                                    .padding(.horizontal)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .background(.gray.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.orange, lineWidth: 4)
            )

        }

        }

}

struct LiveMetricsPausedView_Previews: PreviewProvider {
    
    static var activityDataManager = ActivityDataManager()
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(activityDataManager: activityDataManager, settingsManager: settingsManager)

    static var workoutManager = WorkoutManager(locationManager: locationManager, activityDataManager: activityDataManager,
        settingsManager: settingsManager)

    static var previews: some View {
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
                    
                    HStack {
                        Image(systemName: "arrowshape.forward")
                            .foregroundColor(Color.yellow)
                        Text("0 M")
                                .padding(.trailing, 8)
                                .foregroundColor(Color.yellow)
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: "arrow.up.right.circle")
                            .foregroundColor(Color.yellow)
                        Text(distanceFormatter(distance:
                                                0,
                                              forceMeters: true))
                                .padding(.trailing, 8)
                                .foregroundColor(Color.yellow)
                        Spacer()
                    }
            }
            
            
            Spacer()

            LiveMetricsPausedView(workoutManager: workoutManager)
        }

    }
}
