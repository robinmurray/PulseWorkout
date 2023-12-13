//
//  LocationView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 14/09/2023.
//

import SwiftUI

struct Location: Identifiable {
  let id = UUID()
  let coordinate: CLLocationCoordinate2D
}



struct LocationView: View {
    
    @ObservedObject var locationManager: LocationManager
    

    var body: some View {
        
        TimelineView(.periodic(from: Date(), by: 2)) { context in
            
            if !locationManager.authStatusOk {
                LocationNotAuthView()
                    .navigationTitle("Location")
                    .navigationBarTitleDisplayMode(.large)
            }
            else {
                VStack {
                    Form {
                        Section(header: Text("Current Location")) {

                            HStack {
                                    
                                Text(locationManager.placeName ?? "Geo-location not available")
                                    .foregroundColor(Color.yellow)
                                    .font(locationManager.placeName == nil ? .footnote : .caption)
                                    
                                Spacer()
                                    
                                Button(action: locationManager.setPinnedLocation) {
                                    Image(systemName: "mappin.circle")
                                }
                                .foregroundColor(Color.yellow)
                                .font(.title)
                                .frame(width: 40, height: 40)
                                .background(Color.clear)
                                .clipShape(Circle())
                                .buttonStyle(PlainButtonStyle())
                                    
                            }
                                
                            
                            VStack {
                                
                                HStack {
                                    Text("Longitude")
                                    Spacer()
                                    Text(String(format: "%.4f", locationManager.longitude ?? 0))
                                        .foregroundColor(Color.yellow)
                                }
                                
                                HStack {
                                    Text("Latitude")
                                    Spacer()
                                    Text(String(format: "%.4f", locationManager.latitude ?? 0))
                                        .foregroundColor(Color.yellow)
                                }
                                HStack {
                                    Text("Accuracy")
                                    Spacer()
                                    Text("+/- " + String(format: "%.0f", locationManager.horizontalAccuracy ?? 0) + "m")
                                        .foregroundColor(Color.yellow)
                                }
                                
                                HStack {
                                    Text("Altitude")
                                    Spacer()
                                    Text(String(format: "%.0f", locationManager.altitude ?? 0) + "m")
                                        .foregroundColor(Color.yellow)
                                }
                                HStack {
                                    Text("Accuracy")
                                    Spacer()
                                    Text("+/- " + String(format: "%.0f", locationManager.verticalAccuracy ?? 0) + "m")
                                        .foregroundColor(Color.yellow)
                                }
                                
                                HStack {
                                    Text("Ascent")
                                    Spacer()
                                    Text(String(format: "%.0f", locationManager.totalAscent ?? 0) + "m")
                                        .foregroundColor(Color.yellow)
                                }
                                
                                HStack {
                                    Text("Descent")
                                    Spacer()
                                    Text(String(format: "%.0f", locationManager.totalDescent ?? 0) + "m")
                                        .foregroundColor(Color.yellow)
                                }
                                HStack {
                                    Text("Speed")
                                    Spacer()
                                    Text(speedFormatter(speed: locationManager.speed ?? 0))
                                        .foregroundColor(Color.yellow)
                                }
                                HStack {
                                    Text("Heading")
                                    Spacer()
                                    Text(String(format: "%.0f", locationManager.direction ?? 0))
                                        .foregroundColor(Color.yellow)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .navigationBarTitleDisplayMode(.large)
                        .navigationTitle {
                            Text("Location").foregroundColor(.green)
                        }
                        
                        
                        if locationManager.pinnedLocation != nil {
                            Section(header: Text("Pinned Location")) {
                                VStack {
                                    HStack {
                                        Text(locationManager.pinnedPlaceName ?? "Geo-location not available")
                                            .foregroundColor(Color.blue)
                                            .font(.footnote)
                                        
                                        Spacer()
                                        
                                        Button(action: locationManager.clearPinnedLocation) {
                                            Image(systemName: "mappin.slash.circle")
                                        }
                                        .foregroundColor(Color.blue)
                                        .font(.title)
                                        .frame(width: 40, height: 40)
                                        .background(Color.clear)
                                        .clipShape(Circle())
                                        .buttonStyle(PlainButtonStyle())
                                        
                                    }
                                    
                                    HStack {
                                        Text("Distance")
                                        
                                        Spacer()
                                        Text(distanceFormatter(distance:
                                                                locationManager.pinnedLocationDistance ?? 0))
                                        .foregroundColor(Color.yellow)
                                    }
                                    
                                    NavigationStack {
                                        NavigationLink(
                                            destination: MapView(latitude: locationManager.pinnedLocation!.coordinate.latitude,
                                                                 longitude: locationManager.pinnedLocation!.coordinate.longitude)) {
                                                                     HStack {
                                                                         Text("Map")

                                                                         Spacer()

                                                                         Image(systemName: "map.circle")
                                                                             .foregroundColor(Color.blue)
                                                                             .font(.title)
                                                                             .frame(width: 40, height: 40)
                                                                     }
                                                                     
                                                                 }
                                    }
                                }
                                
                            }
                            
                        }
                        
                    }
                    
                }
                .onAppear(perform: locationManager.startFGLocationServices)
                .onDisappear(perform: locationManager.stopFGLocationServices)
                
            }

        }
    }
        
}

struct LocationView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var previews: some View {
        LocationView(locationManager: locationManager)
    }
}
