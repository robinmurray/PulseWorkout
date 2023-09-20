//
//  LocationManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 13/09/2023.
//

import Foundation
import CoreLocation


class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var altitude: Double?
    @Published var horizontalAccuracy: Double?
    @Published var verticalAccuracy: Double?
    @Published var speed: Double?
    @Published var direction: Double?
    @Published var placeName: String?
    

    var locManager: CLLocationManager
    var backgroundActive: Bool = false
    var foregroundActive: Bool = false
    var authStatusOk: Bool = false
    var headingsOk: Bool
    var location: CLLocation?
    var lastGeoLocation: CLLocation?
    let GeoLocationAccuracy: Double = 10
    @Published var pinnedLocation: CLLocation?
    @Published var pinnedPlaceName: String?
    @Published var pinnedLocationDistance: Double?
    
    override init() {

        locManager = CLLocationManager()
        headingsOk = CLLocationManager.headingAvailable()
        print("headingsOk \(headingsOk)")
        print("locationsOk \(CLLocationManager.locationServicesEnabled())")
        super.init()
        
        locManager.delegate = self
        
        // Use requestAlwaysAuthorization
        // updates even when app is running in the background
        locManager.requestAlwaysAuthorization()
        
        locManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locManager.distanceFilter = kCLDistanceFilterNone
        
        getPinnedLocation()
        

    }

    /// Read the pinned location from user defaults, if is set
    func getPinnedLocation() {
        
        let pinLatitude = UserDefaults().double(forKey: "pinnedLocationLatitude")
        let pinLongitude = UserDefaults().double(forKey: "pinnedLocationLongitude")

        if pinLatitude != 0 && pinLongitude != 0 {
            pinnedLocation = CLLocation(latitude: pinLatitude, longitude: pinLongitude)
            pinnedPlaceName = UserDefaults().string(forKey: "pinnedLocationPlaceName")
        }
        
        
        
    }
    
    /// Set a pinned location and store to user defaults
    func setPinnedLocation() {
        
        pinnedLocation = location
        pinnedPlaceName = placeName
        
        if pinnedLocation != nil {
            
            UserDefaults().set( pinnedLocation!.coordinate.latitude, forKey: "pinnedLocationLatitude")
            UserDefaults().set( pinnedLocation!.coordinate.longitude, forKey: "pinnedLocationLongitude")

            UserDefaults().set( pinnedPlaceName, forKey: "pinnedLocationPlaceName")

        }
    }
    
    /// Remove pinned location and clear from user defaults
    func clearPinnedLocation() {
        UserDefaults().removeObject(forKey: "pinnedLocationLatitude")
        UserDefaults().removeObject(forKey: "pinnedLocationLongitude")
        UserDefaults().removeObject(forKey: "pinnedLocationPlaceName")

        pinnedLocation = nil
        pinnedPlaceName = nil
        pinnedLocationDistance = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            switch manager.authorizationStatus {
            case .notDetermined:
                print("When user did not yet determine")
                authStatusOk = false
            case .restricted:
                print("Restricted by parental control")
                authStatusOk = false
            case .denied:
                print("When user select option Dont't Allow")
                authStatusOk = false
            case .authorizedWhenInUse:
                print("When user select option Allow While Using App or Allow Once")
                authStatusOk = false
            case .authorizedAlways:
                print("When user select option always")
                authStatusOk = true
            @unknown default:
                print("default")
                authStatusOk = false
            }
        }
    
    /// Start location services with background updates switched on.
    /// Use this for location service for workouts when background app updating is needed.
    func startBGLocationServices() {
        
        locManager.allowsBackgroundLocationUpdates = true

        if authStatusOk {
            locManager.startUpdatingLocation()
            backgroundActive = true
        }
    }
    
    /// Stop location services if not active in foreground mode as well as background mode.
    func stopBGLocationServices() {
        locManager.allowsBackgroundLocationUpdates = false
        backgroundActive = false
        
        if !foregroundActive {
            locManager.stopUpdatingLocation()

            latitude = nil
            longitude = nil
            altitude = nil
            speed = nil
            horizontalAccuracy = nil
            direction = nil
            pinnedLocationDistance = nil
        }

    }

    /// Start location services without background update permission
    func startFGLocationServices() {
        
        if authStatusOk {
            locManager.startUpdatingLocation()
            foregroundActive = true
        }
    }
    
    /// Stop location services if not active in background mode as well as forground mode.
    func stopFGLocationServices() {

        foregroundActive = false
        
        if !backgroundActive {
            locManager.stopUpdatingLocation()

            latitude = nil
            longitude = nil
            altitude = nil
            speed = nil
            horizontalAccuracy = nil
            direction = nil
            pinnedLocationDistance = nil
        }

    }


    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        print("Update location \(locations)")
        // Handle location update
        location = locations.last
        if location != nil {
            latitude = location!.coordinate.latitude
            longitude = location!.coordinate.longitude
            speed = location!.speed
            altitude = location!.altitude
            horizontalAccuracy = location!.horizontalAccuracy
            verticalAccuracy = location!.verticalAccuracy
            direction = location!.course
            
            if pinnedLocation != nil {
                pinnedLocationDistance = location!.distance(from: pinnedLocation!)
            }
            
            // Get Geo location if running in foreground mode and has moved from last geolocation
            if foregroundActive {
                if lastGeoLocation == nil {
                    getGeoLocation()
                } else if location!.distance(from: lastGeoLocation!) > GeoLocationAccuracy {
                    getGeoLocation()
                }
            }

        }
        

    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        // Handle failure to get a user’s location
    }
    
    func lookUpCurrentLocation(completionHandler: @escaping (CLPlacemark?)
                    -> Void ) {
        // Use the last reported location.
        if let lastLocation = location {
            let geocoder = CLGeocoder()
                
            // Look up the location and pass it to the completion handler
            geocoder.reverseGeocodeLocation(lastLocation,
                        completionHandler: { (placemarks, error) in
                if error == nil {
                    self.lastGeoLocation = lastLocation
                    let firstLocation = placemarks?[0]
                    completionHandler(firstLocation)
                    
                }
                else {
                 // An error occurred during geocoding.
                    completionHandler(nil)
                }
            })
        }
        else {
            // No location was available.
            completionHandler(nil)
        }
    }
    
    func lookUpCurrentLocationCompletion(placemark: CLPlacemark?) {
        if placemark != nil {
            placeName = placemark?.name
        }
    }
    
    func getGeoLocation() {
        lookUpCurrentLocation(completionHandler: lookUpCurrentLocationCompletion)
    }
}


