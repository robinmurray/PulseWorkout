//
//  MapView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 16/11/2023.
//

import SwiftUI
import MapKit
import Accelerate

struct MapView: View {
    
    var pinLocation: CLLocationCoordinate2D?
    // @State private
    var route: MapPolyline?

    @State private var cameraPos: MapCameraPosition
    @State private var displayUserAnnotation: Bool = false
    
    
    init(pinLatitude: Double, pinLongitude: Double) {
        pinLocation = CLLocationCoordinate2D(latitude: pinLatitude, longitude: pinLongitude)

        cameraPos = MapCameraPosition.region( MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: pinLatitude, longitude: pinLongitude), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)) )
        cameraPos = MapCameraPosition.userLocation( followsHeading: true, fallback: cameraPos)
        
        displayUserAnnotation = true

    }
    
    init(routeCoordinates: [CLLocationCoordinate2D]) {

        var localCameraPos: MapCameraPosition
        
        localCameraPos = MapCameraPosition.region( MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)) )
        localCameraPos = MapCameraPosition.userLocation( followsHeading: true, fallback: localCameraPos)
    
        if routeCoordinates.count > 0 {

            route = MapPolyline(coordinates: routeCoordinates, contourStyle: .straight)
            let latitudes = routeCoordinates.map({$0.latitude})
            let longitudes = routeCoordinates.map({$0.longitude})
            let meanLatitude = vDSP.mean(latitudes)
            let meanLongitude = vDSP.mean(longitudes)
            let routeCenter = CLLocationCoordinate2D(latitude: meanLatitude,
                                                     longitude: meanLongitude)
            let latitudeSpan = max( meanLatitude - vDSP.minimum(latitudes),
                                    vDSP.maximum(latitudes) - meanLatitude ) + 0.005
            let longitudeSpan = max( meanLongitude - vDSP.minimum(longitudes),
                                    vDSP.maximum(longitudes) - meanLongitude ) + 0.005
            
            localCameraPos = MapCameraPosition.region( MKCoordinateRegion(center: routeCenter,
                                                  span: MKCoordinateSpan(latitudeDelta: latitudeSpan,       longitudeDelta: longitudeSpan)))
        }

        cameraPos = localCameraPos
        displayUserAnnotation = false
    }
    
    var body: some View {
        /*
        Map(coordinateRegion: $region,
            interactionModes: .zoom,
            annotationItems: [Location(coordinate: pinLocation)], annotationContent: { place in
            MapMarker(coordinate: place.coordinate,
                   tint: Color.yellow)
        }) */
        Map(position: $cameraPos, interactionModes: [.pan, .zoom]) {

            // Display current location
            if displayUserAnnotation {
                UserAnnotation()
            }
            
            // Display pinned location if there is one
            if let displayPinLocation = pinLocation {
                Marker("Pinned location", coordinate: displayPinLocation)
            }
            
            // Display route if there is one
            if let displayRoute = route {
                displayRoute.stroke(.blue, lineWidth: 5).mapOverlayLevel(level: .aboveRoads)
            }
            
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .all))
        .mapControls {
            VStack {
                MapCompass()
                MapUserLocationButton()
            }
        }


    }
        
}


struct MapView_Previews: PreviewProvider {
    
    static var latitude = 0.123
    static var longitude = 20.234
    
    static var previews: some View {
        MapView(pinLatitude: latitude, pinLongitude: longitude)
    }
}
