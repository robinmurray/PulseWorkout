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
    @Published var totalAscent: Double?
    @Published var totalDescent: Double?
    @Published var speed: Double?
    @Published var direction: Double?
    @Published var placeName: String?
    
    var lastAltitude: Double?
    
    // Hold last 5 altitude readings to take moving average to smooth out errors
    var smoothedAltitudeList: [Double] = []

    var locManager: CLLocationManager
    var backgroundActive: Bool = false
    var foregroundActive: Bool = false
    var authStatusOk: Bool = false
    var headingsOk: Bool
    var location: CLLocation?
    var lastGeoLocation: CLLocation?
    var activityDataManager: ActivityDataManager
    var settingsManager: SettingsManager
    @Published var pinnedLocation: CLLocation?
    @Published var pinnedPlaceName: String?
    @Published var pinnedLocationDistance: Double?
    
    /// Set when activity is auto-paused when speed < limit
    var isPaused: Bool = false
    
    /// When latest auto-pause started
    var autoPauseStart: Date?
    
    /// Total duration of auto-pauses (not including current one if currently auto-paused
    var totalAutoPauseDuration: Double = 0

    let GeoLocationAccuracy: Double = 10
    
    
    init(activityDataManager: ActivityDataManager, settingsManager: SettingsManager) {

        self.activityDataManager = activityDataManager
        self.settingsManager = settingsManager
        locManager = CLLocationManager()
        headingsOk = CLLocationManager.headingAvailable()

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
            
            if pinnedPlaceName == nil { getPinnedGeoLocation() }
        }
    }
    
    
    /// Set a pinned location and store to user defaults
    func setPinnedLocation() {
        
        pinnedLocation = location
        pinnedPlaceName = nil
        
        if pinnedLocation != nil {
            
            UserDefaults().set( pinnedLocation!.coordinate.latitude, forKey: "pinnedLocationLatitude")
            UserDefaults().set( pinnedLocation!.coordinate.longitude, forKey: "pinnedLocationLongitude")
            UserDefaults().removeObject(forKey: "pinnedLocationPlaceName")

        }
        getPinnedGeoLocation()
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
        
        print("starting BG location services")
        
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
            lastAltitude = nil
            smoothedAltitudeList = []
            totalAscent = nil
            totalDescent = nil
            speed = nil
            horizontalAccuracy = nil
            direction = nil
            pinnedLocationDistance = nil
        }

    }

    
    /// Start location services without background update permission
    func startFGLocationServices() {
        
        if authStatusOk {
            if !backgroundActive {
                locManager.startUpdatingLocation()
            } else {
                getCurrentGeoLocation()
            }
            
            foregroundActive = true
            lastGeoLocation = nil // force update of geo location
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
            lastAltitude = nil
            smoothedAltitudeList = []
            totalAscent = nil
            totalDescent = nil
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

            /*
            if altitude != nil && lastAltitude != nil {
                if altitude! > lastAltitude! {
                    totalAscent = (totalAscent ?? 0) + (altitude! - lastAltitude!)
                } else {
                    totalDescent = (totalDescent ?? 0) + (lastAltitude! - altitude!)
                }
            }
            
            lastAltitude = altitude
            */
            
            if altitude != nil {
                let smoothingLength = 5
                var smoothedAltitude: Double?
                if smoothedAltitudeList.count == smoothingLength {
                    smoothedAltitude = smoothedAltitudeList.reduce(0, +) / 5
                    smoothedAltitudeList.removeFirst()
                    
                }

                smoothedAltitudeList.append(altitude!)
                
                if smoothedAltitudeList.count == smoothingLength {
                    let thisSmoothedAltitude = smoothedAltitudeList.reduce(0, +) / 5
                    let prevSmoothedAltitude = smoothedAltitude ?? thisSmoothedAltitude     // ensure zero change on first ever calc!
                    if thisSmoothedAltitude >= prevSmoothedAltitude {
                        totalAscent = (totalAscent ?? 0) + (thisSmoothedAltitude - prevSmoothedAltitude)
                    } else {
                        totalDescent = (totalDescent ?? 0) + (prevSmoothedAltitude - thisSmoothedAltitude)
                    }
                }
            }
            
            // auto pause if configured and speed < pause speed
            if settingsManager.autoPause {
                let speedKPH = (speed ?? 999) * 3.6
                let isNowPaused = (speedKPH < 0.2) ? true : false
                
                // if auto-pause starting...
                if isNowPaused && !isPaused {
                    isPaused = true
                    autoPauseStart = Date()
                }
                
                // if auto-pause ending...
                if !isNowPaused && isPaused {
                    isPaused = false
                    let pauseDuration = Date().timeIntervalSince(autoPauseStart!)
                    autoPauseStart = nil
                    totalAutoPauseDuration += pauseDuration
                    
                }
            }
            
            
            activityDataManager.set(speed: speed)
            activityDataManager.set(latitude: latitude)
            activityDataManager.set(longitude: longitude)
            activityDataManager.set(totalAscent: totalAscent)
            activityDataManager.set(totalDescent: totalDescent)
            activityDataManager.set(pausedTime: totalAutoPauseDuration)

            if pinnedLocation != nil {
                pinnedLocationDistance = location!.distance(from: pinnedLocation!)
            }
            
            // Get Geo location if running in foreground mode and has moved from last geolocation
            if foregroundActive { getCurrentGeoLocation() }

        }
        

    }

    
    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        // Handle failure to get a user’s location
    }
    
    
    func getGeoLocation(lookupLocation: CLLocation?, setLastGeoLocation: Bool = true,  completionHandler: @escaping (CLPlacemark?)
                    -> Void ) {
        // Use the last reported location.
        if let lastLocation = lookupLocation {
            let geocoder = CLGeocoder()
                
            // Look up the location and pass it to the completion handler
            geocoder.reverseGeocodeLocation(lastLocation,
                        completionHandler: { (placemarks, error) in
                if error == nil {
                    if setLastGeoLocation { self.lastGeoLocation = lastLocation }
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
    
    
    func currentLocationCompletion(placemark: CLPlacemark?) {
        if placemark != nil {
            placeName = placemark?.name
        }
    }
    
    
    func getCurrentGeoLocation() {
        if lastGeoLocation == nil {
            getGeoLocation(lookupLocation: location,
                                  completionHandler: currentLocationCompletion)
        } else if location!.distance(from: lastGeoLocation!) > GeoLocationAccuracy {
            getGeoLocation(lookupLocation: location,
                                  completionHandler: currentLocationCompletion)
        }
    }

    
    @objc func getPinnedGeoLocation() {
        guard let lookupLocation = pinnedLocation else { return }
        
        getGeoLocation(lookupLocation: lookupLocation,
                       completionHandler: pinnedLocationCompletion)

    }

    
    func pinnedLocationCompletion(placemark: CLPlacemark?) {
        if placemark != nil {
            print("Setting pinned place name")
            pinnedPlaceName = placemark?.name
            UserDefaults().set( pinnedPlaceName, forKey: "pinnedLocationPlaceName")
        } else { setDeferredGetPinnedLocation() }
    }

    
    func setDeferredGetPinnedLocation() {
        let deferredTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(getPinnedGeoLocation), userInfo: nil, repeats: false)
        deferredTimer.tolerance = 5

    }
    
}


