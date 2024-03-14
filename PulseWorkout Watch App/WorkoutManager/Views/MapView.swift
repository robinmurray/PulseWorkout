//
//  MapView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 16/11/2023.
//

import SwiftUI
import MapKit

struct MapView: View {
    
    var latitude: Double
    var longitude: Double
    var pinLocation: CLLocationCoordinate2D
    
    @State private var region: MKCoordinateRegion
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        pinLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    }


    var body: some View {
        Map(coordinateRegion: $region,
            interactionModes: .zoom,
            annotationItems: [Location(coordinate: pinLocation)], annotationContent: { place in
            MapMarker(coordinate: place.coordinate,
                   tint: Color.yellow)
        })
        .navigationTitle {
            HStack {
                Image(systemName: "map.circle")
                    .foregroundColor(Color.blue)
                    .clipShape(Circle())

                Text("Pinned Location")
                    .foregroundColor(Color.blue)
            }
        }


    }
        
}


struct MapView_Previews: PreviewProvider {
    
    static var latitude = 0.123
    static var longitude = 20.234
    
    static var previews: some View {
        MapView(latitude: latitude, longitude: longitude)
    }
}
