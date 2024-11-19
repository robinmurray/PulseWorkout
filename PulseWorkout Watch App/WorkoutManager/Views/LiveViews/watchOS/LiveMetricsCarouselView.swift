//
//  LiveMetricsCarouselView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 05/09/2024.
//

import SwiftUI

struct LiveMetricsCarouselView: View {
    
    // to manage fixed height scrolling view
    @State private var scrollStackheight: CGFloat = 0
    var activityData: ActivityRecord
    var contextDate: Date

    
    func scrollPosition(scrollDate: Date, scrollInterval: Int, scrollItems: Int) -> Int {
        
        let seconds = Calendar.current.component(.second, from: scrollDate)
        let scrollCount: Int = seconds / scrollInterval
        let scrollPos: Int = scrollCount % scrollItems
        
        return scrollPos
    }
    
    var body: some View {
        
        VStack {

            switch scrollPosition(scrollDate: contextDate,
                                  scrollInterval: 2,
                                  scrollItems: 4) {
            case 0:
                LiveMetricCarouselItem(
                    metric1: (image: distanceIcon,
                              text: distanceFormatter(distance: activityData.distanceMeters)),
                    metric2: (image: ascentIcon,
                              text: distanceFormatter(distance: activityData.totalAscent ?? 0,
                                                          forceMeters: true))
                )
                    .modifier(GetHeightModifier(height: $scrollStackheight))

            case 1:
                // Speed and Average Speed
                LiveMetricCarouselItem(
                    metric1: (image: speedIcon,
                              text: speedFormatter(speed: activityData.speed ?? 0)),
                    metric2: (image: meanIcon,
                              text: speedFormatter(speed: activityData.averageSpeed))
                )
                    .modifier(GetHeightModifier(height: $scrollStackheight))
                
            case 2:
                // Power and Average Power
                LiveMetricCarouselItem(
                    metric1: (image: powerIcon,
                              text: Measurement(value: Double(activityData.watts ?? 0),
                                                unit: UnitPower.watts)
                               .formatted(.measurement(width: .abbreviated,
                                                       usage: .asProvided))),
                    metric2: (image: meanIcon,
                              text: Measurement(value: Double(activityData.averagePower),
                                                unit: UnitPower.watts)
                               .formatted(.measurement(width: .abbreviated,
                                                       usage: .asProvided)))
                )
                .modifier(GetHeightModifier(height: $scrollStackheight))
                
            case 3:
                // Cadence and Average Cadence
                LiveMetricCarouselItem(
                    metric1: (image: cadenceIcon,
                              text: String(activityData.cadence ?? 0)),
                    metric2: (image: meanIcon,
                              text: String(activityData.averageCadence))
                )
                .modifier(GetHeightModifier(height: $scrollStackheight))
                   
            default:
                LiveMetricCarouselItem(
                    metric1: (image: distanceIcon,
                              text: distanceFormatter(distance: activityData.distanceMeters)),
                    metric2: (image: ascentIcon,
                              text: distanceFormatter(distance: activityData.totalAscent ?? 0,
                                                          forceMeters: true))
                )
                    .modifier(GetHeightModifier(height: $scrollStackheight))
                    
            }
                

        }
        .frame(height: scrollStackheight)

    }
}

struct LiveMetricsCarouselView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()

    static var previews: some View {
        LiveMetricsCarouselView(activityData: ActivityRecord(settingsManager: settingsManager), contextDate: Date())
    }
}

