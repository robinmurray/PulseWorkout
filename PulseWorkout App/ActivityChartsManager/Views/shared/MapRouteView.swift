//
//  MapRouteView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 16/11/2023.
//

import SwiftUI
import MapKit
import Accelerate
import CloudKit

struct MapRouteView: View {
    
    @State var activityRecord: ActivityRecord
    @ObservedObject var activityChartsController: ActivityChartsController

    var route: MapPolyline?

    @State private var displayUserAnnotation: Bool = false
    
    init(activityRecord: ActivityRecord) {
        self.activityRecord = activityRecord
        self.activityChartsController = ActivityChartsController()
    }
    
    
    var body: some View {
        
        ZStack {
            if activityChartsController.recordFetchFailed {
                FetchFailedView()
            } else {
                Map(position: $activityChartsController.cameraPos, interactionModes: [.pan, .zoom]) {
                    // Display current location
                    if displayUserAnnotation {
                        UserAnnotation()
                    }
                    
                    // Display route if there is one
                    if activityChartsController.routeCoordinates.count > 0 {
                        MapPolyline(coordinates: activityChartsController.routeCoordinates, contourStyle: .straight).stroke(.red, lineWidth: 1).mapOverlayLevel(level: .aboveRoads)
                    }
                    
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all))
                .mapControls {
                    VStack {
                        MapCompass()
                        MapUserLocationButton()
                    }
                }
                
                if activityChartsController.buildingChartTraces {
                    ProgressView()
                }
            }

        }
        .onAppear(perform: {
            activityChartsController.buildMapTrace(recordID: activityRecord.recordID)
        })

    }
        
}


struct MapRouteView_Previews: PreviewProvider {
    
    static var activityRecord = ActivityRecord()
    
    static var previews: some View {
        MapRouteView(activityRecord: activityRecord)
    }
}
