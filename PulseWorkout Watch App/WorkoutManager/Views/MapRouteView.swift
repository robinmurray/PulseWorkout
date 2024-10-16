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
    @ObservedObject var dataCache: DataCache

    var route: MapPolyline?

//    @State private var cameraPos: MapCameraPosition
    @State private var displayUserAnnotation: Bool = false
    
    func buildRoute(recordID: CKRecord.ID) {

        // Fetch data from Cloudkit if necssary and build map data
        dataCache.buildChartTraces(recordID: activityRecord.recordID)

    }
    
    var body: some View {
        
        ZStack {

            Map(position: $dataCache.cameraPos, interactionModes: [.pan, .zoom]) {
                // Display current location
                if displayUserAnnotation {
                    UserAnnotation()
                }
                
                // Display route if there is one
                if dataCache.routeCoordinates.count > 0 {
                    MapPolyline(coordinates: dataCache.routeCoordinates, contourStyle: .straight).stroke(.blue, lineWidth: 5).mapOverlayLevel(level: .aboveRoads)
                }
                
            }
            .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all))
            .mapControls {
                VStack {
                    MapCompass()
                    MapUserLocationButton()
                }
            }
            
            if dataCache.buildingChartTraces {
                ProgressView()
            }
        }
        .onAppear(perform: {
            buildRoute(recordID: activityRecord.recordID)
        })

    }
        
}


struct MapRouteView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var activityRecord = ActivityRecord(settingsManager: settingsManager)
    static var dataCache = DataCache(settingsManager: settingsManager)
    
    static var previews: some View {
        MapRouteView(activityRecord: activityRecord, dataCache: dataCache)
    }
}
