//
//  ViewParameters.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 22/06/2025.
//

import Foundation
import SwiftUI

struct ViewParameters {
    var imageSystemName: String
    var titleText: String
    var foregroundColor: Color
    var totalLabel: String
    var byZonePropertyName: String?
    var navigationTitle: String
    var stackedBarType: StackedBarType
}

let PropertyViewParamaters: [String: ViewParameters] = [
    "activities": ViewParameters(imageSystemName: "figure.run", titleText: "Activities",
                                 foregroundColor: activitiesColor, totalLabel: "Total Activities", byZonePropertyName: "activitiesByType",
                                 navigationTitle: "Activities", stackedBarType: .activityType),
    "TSS": ViewParameters(imageSystemName: "figure.strengthtraining.traditional.circle", titleText: "Training Load",
                          foregroundColor: TSSColor, totalLabel: "Total Load", byZonePropertyName: "TSSByZone",
                          navigationTitle: "Training Load", stackedBarType: .powerZone),
    "distanceMeters": ViewParameters(imageSystemName: distanceIcon, titleText: "Distance",
                                     foregroundColor: distanceColor, totalLabel: "Total Distance", byZonePropertyName: "distanceMetersByType",
                                     navigationTitle: "Distance", stackedBarType: .activityType),
    "time": ViewParameters(imageSystemName: "stopwatch", titleText: "Activity Time - by Heart Rate Zone",
                           foregroundColor: timeByHRColor, totalLabel: "Total Time", byZonePropertyName: "timeByZone",
                           navigationTitle: "Activity Time by HR Zone", stackedBarType: .powerZone)
]


