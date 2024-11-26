//
//  LocationManager.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 13/09/2023.
//

import Foundation
import CoreLocation
import os

/// Use for smoothing ascent/descent calculations - only count changes in elevation greater than this (and greater than current GPS vertical accuracy)
let MIN_VERTICAL_ACCURACY: Double = 4



class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    var horizontalAccuracy: Double?
    var verticalAccuracy: Double?
    var totalAscent: Double?
    var totalDescent: Double?
    var speed: Double?
    var direction: Double?
    var placeName: String?
    
    /// Set when activity is auto-paused when speed < limit
    ///
    var isPaused: Bool = false
    
    var lastAltitude: Double?
    
    var locManager: CLLocationManager
    var backgroundActive: Bool = false
    var foregroundActive: Bool = false
    var authStatusOk: Bool = false
    var headingsOk: Bool
    var location: CLLocation?
    var lastGeoLocation: CLLocation?

    var settingsManager: SettingsManager
    @Published var pinnedLocation: CLLocation?
    var pinnedPlaceName: String?
    var pinnedLocationDistance: Double?
    var liveActivityRecord: ActivityRecord?

    
    /// When latest auto-pause started
    var autoPauseStart: Date?
    
    let GeoLocationAccuracy: Double = 10
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "locationManager")
    
    
    init(settingsManager: SettingsManager) {

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
                logger.debug("When user did not yet determine")
                authStatusOk = false
            case .restricted:
                logger.debug("Restricted by parental control")
                authStatusOk = false
            case .denied:
                logger.debug("When user select option Dont't Allow")
                authStatusOk = false
            case .authorizedWhenInUse:
                logger.debug("When user select option Allow While Using App or Allow Once")
                authStatusOk = false
            case .authorizedAlways:
                logger.debug("When user select option always")
                authStatusOk = true
            @unknown default:
                logger.debug("default")
                authStatusOk = false
            }
        }
    
    
    /// Start location services with background updates switched on.
    /// Use this for location service for workouts when background app updating is needed.
    func startBGLocationServices(liveActityRecord: ActivityRecord) {
        
        logger.debug("starting BG location services")

        self.liveActivityRecord = liveActityRecord
        autoPauseStart = nil
        isPaused = false
        if liveActivityRecord != nil {
            liveActivityRecord!.isPaused = false
        }
        locManager.allowsBackgroundLocationUpdates = true

        if authStatusOk {
            locManager.startUpdatingLocation()
            backgroundActive = true
        }
    }
    
    
    /// reset any live location fields to nil if locationservices disabled
    func resetLocationData() {

        latitude = nil
        longitude = nil
        altitude = nil
        lastAltitude = nil
        totalAscent = nil
        totalDescent = nil
        speed = nil
        horizontalAccuracy = nil
        direction = nil
        pinnedLocationDistance = nil
        
        autoPauseStart = nil
        isPaused = false
        if liveActivityRecord != nil {
            liveActivityRecord!.isPaused = false
        }
        
    }
    
    
    func stopLocationSession() {
        
        if isPaused && (autoPauseStart != nil) {
            if liveActivityRecord != nil {
                liveActivityRecord!.increment(pausedTime: Date().timeIntervalSince(autoPauseStart!))
            }
        }

        autoPauseStart = nil
        isPaused = false
        if liveActivityRecord != nil {
            liveActivityRecord!.isPaused = false
        }
        stopBGLocationServices()
        
        
    }
    
    
    /// Stop location services if not active in foreground mode as well as background mode.
    func stopBGLocationServices() {
        locManager.allowsBackgroundLocationUpdates = false
        backgroundActive = false
        
        if !foregroundActive {
            locManager.stopUpdatingLocation()

            resetLocationData()
        }
        liveActivityRecord = nil

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

            resetLocationData()
        }

    }


    /// Return length of current pause now
    func currentPauseDuration() -> TimeInterval {
        
        return currentPauseDurationAt(at: Date())
        
    }

    /// Return length of current pause at a given date
    func currentPauseDurationAt(at: Date) -> TimeInterval {
        
        if (!isPaused) || (autoPauseStart == nil) {return TimeInterval(0)}
        
        let duration = at.timeIntervalSince(autoPauseStart!)
        if Int(duration) < settingsManager.minAutoPauseSeconds {
            return TimeInterval(0)
        }
        return duration
        
    }

    
    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        logger.debug("Update location \(locations)")
        
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

            // backgroundActive => workout is active
            if backgroundActive {
                
                // Calculate ascent and descent taking to account vertical accuracy
                if altitude != nil && lastAltitude != nil && verticalAccuracy != nil  && verticalAccuracy != -1 {
                    // Only update altitude if change is greater than current accuracy
                    if abs(altitude! - lastAltitude!) < max(abs(verticalAccuracy!), MIN_VERTICAL_ACCURACY) {
                        altitude = lastAltitude
                    }
                    if altitude! > lastAltitude! {
                        totalAscent = (totalAscent ?? 0) + (altitude! - lastAltitude!)
                    } else {
                        totalDescent = (totalDescent ?? 0) + (lastAltitude! - altitude!)
                    }
                }
                lastAltitude = altitude

                // auto pause if configured and speed < pause speed
                if liveActivityRecord!.autoPause == true {
                    let speedKPH = (speed ?? 999) * 3.6
                    let isNowPaused = (speedKPH <= settingsManager.autoPauseSpeed) ||
                                       ((isPaused == true) && (speedKPH < settingsManager.autoResumeSpeed) ) ? true : false
                    
                    // if auto-pause starting...
                    if isNowPaused && !isPaused {
                        isPaused = true
                        if liveActivityRecord != nil {
                            liveActivityRecord!.isPaused = true
                        }
                        autoPauseStart = Date()
                    }
                    
                    // if auto-pause ending...
                    if !isNowPaused && isPaused {
                        let pauseDuration = currentPauseDuration()
                        isPaused = false
                        if liveActivityRecord != nil {
                            liveActivityRecord!.isPaused = false
                            liveActivityRecord!.increment(pausedTime: pauseDuration)
                        }
                        autoPauseStart = nil
                        
                        
                    }
                } else {
                    isPaused = false
                    if liveActivityRecord != nil {
                        liveActivityRecord!.isPaused = false
                    }
                }
                
                if liveActivityRecord != nil {
                    liveActivityRecord!.set(speed: speed)
                    liveActivityRecord!.set(latitude: latitude)
                    liveActivityRecord!.set(longitude: longitude)
                    liveActivityRecord!.set(totalAscent: totalAscent)
                    liveActivityRecord!.set(totalDescent: totalDescent)
                    liveActivityRecord!.set(altitudeMeters: altitude)
                }
                
            }
             

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
        logger.error("Failed to get user location with error \(error)")
        // Handle failure to get a user’s location
        
        if error._code == CLError.Code.locationUnknown.rawValue {
            logger.error("Location unknown - retrying")
        }

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
            logger.debug("Setting pinned place name")
            pinnedPlaceName = placemark?.name
            UserDefaults().set( pinnedPlaceName, forKey: "pinnedLocationPlaceName")
        } else { setDeferredGetPinnedLocation() }
    }

    
    func setDeferredGetPinnedLocation() {
        let deferredTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(getPinnedGeoLocation), userInfo: nil, repeats: false)
        deferredTimer.tolerance = 5

    }
    
}


