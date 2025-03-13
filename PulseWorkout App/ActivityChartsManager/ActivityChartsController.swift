//
//  ActivityChartsController.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 16/10/2024.
//

import Foundation
import CloudKit
import MapKit
import SwiftUI


class ActivityChartsController: NSObject, ObservableObject {
    
    var dataCache: DataCache
    @Published var buildingChartTraces: Bool = false
    @Published var recordFetchFailed: Bool = false
    @Published var chartTraces: [ActivityChartTraceData] = []
    let settingsManager: SettingsManager = SettingsManager.shared
 
    
    @Published var routeCoordinates: [CLLocationCoordinate2D] = []
    @Published var cameraPos: MapCameraPosition = MapCameraPosition.region( MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)) )
    
    init(dataCache: DataCache) {
        self.dataCache = dataCache

    }
    
    func buildChartTraces(recordID: CKRecord.ID) {
        
        buildingChartTraces = true
        recordFetchFailed = false
        
        dataCache.fetchRecord(recordID: recordID,
                              completionFunction: self.setChartTraces,
                              completionFailureFunction: self.fetchFailed)
        
    }

    func routeCoordinates(activityRecord: ActivityRecord) -> [CLLocationCoordinate2D] {
        
        // Create list of non-null locations
        return activityRecord.trackPoints.filter(
            {$0.latitude != nil && $0.longitude != nil}).map(
                {CLLocationCoordinate2D(latitude: $0.latitude!, longitude: $0.longitude!)})

    }
    
    func heartRateTrace(activityRecord: ActivityRecord) -> ActivityChartTraceData {
        
        let traceBuilder = ActivityChartTraceBuilder(defaultPrimaryMax: 150,
                                                     backgroundAxisSuffix: "M",
                                                     averagesIncludeZeros: false)
        let trace = traceBuilder.build(
            id: "Heart Rate",
            colorScheme: heartRateColor,
            displayPrimaryAverage: true,
            timeDistanceSeries: activityRecord.trackPoints.map( { TimeDistance( time: $0.time, distanceMeters: $0.distanceMeters ?? 0) } ),
            primaryDataSeries: activityRecord.trackPoints.map( {$0.heartRate } ),
            backgroundDataSeries: activityRecord.trackPoints.map( {$0.altitudeMeters } ))
        
        return trace

    }
    
    
    func powerTrace(activityRecord: ActivityRecord) -> ActivityChartTraceData {
    
        let traceBuilder = ActivityChartTraceBuilder(defaultPrimaryMax: 100,
                                                     backgroundAxisSuffix: "M",
                                                     averagesIncludeZeros: settingsManager.avePowerZeros)
        
        traceBuilder.rollingAverageCount = max(Int(SettingsManager.shared.cyclePowerGraphSeconds / 2), 1)
        let trace = traceBuilder.build(
            id: "Power",
            colorScheme: powerColor,
            displayPrimaryAverage: true,
            timeDistanceSeries: activityRecord.trackPoints.map( { TimeDistance( time: $0.time, distanceMeters: $0.distanceMeters ?? 0 ) } ),
            primaryDataSeries: activityRecord.trackPoints.map( { Double($0.watts ?? 0) } ),
            backgroundDataSeries: activityRecord.trackPoints.map( {$0.altitudeMeters } ))
        
        return trace

    }

    func cadenceTrace(activityRecord: ActivityRecord) -> ActivityChartTraceData {
    
        let traceBuilder = ActivityChartTraceBuilder(defaultPrimaryMax: 100,
                                                     backgroundAxisSuffix: "M",
                                                     averagesIncludeZeros: settingsManager.aveCadenceZeros)
        traceBuilder.rollingAverageCount = max(Int(SettingsManager.shared.cyclePowerGraphSeconds / 2), 1)
        let trace = traceBuilder.build(
            id: "Cadence",
            colorScheme: cadenceColor,
            displayPrimaryAverage: true,
            timeDistanceSeries: activityRecord.trackPoints.map( { TimeDistance( time: $0.time, distanceMeters: $0.distanceMeters ?? 0 ) } ),
            primaryDataSeries: activityRecord.trackPoints.map( { Double($0.cadence ?? 0) } ),
            backgroundDataSeries: activityRecord.trackPoints.map( {$0.altitudeMeters } ))
        
        return trace

    }
    
    func ascentTrace(activityRecord: ActivityRecord) -> ActivityChartTraceData {
        
        let traceBuilder = ActivityChartTraceBuilder(defaultPrimaryMax: 100,
                                                     backgroundAxisSuffix: "M",
                                                     averagesIncludeZeros: true)
        let trace = traceBuilder.build(
            id: "Ascent",
            colorScheme: distanceColor,
            displayPrimaryAverage: false,
            timeDistanceSeries: activityRecord.trackPoints.map( { TimeDistance( time: $0.time, distanceMeters: $0.distanceMeters ?? 0 ) } ),
            primaryDataSeries: getAscentFromAltitude(altitudeArray: activityRecord.trackPoints.map( { $0.altitudeMeters } )),
            backgroundDataSeries: activityRecord.trackPoints.map( {$0.altitudeMeters } ))
        
        return trace
        
    }
    
    func setChartTraces(activityRecord: ActivityRecord) {
        
        DispatchQueue.main.async {
            self.chartTraces = []
            
            if activityRecord.heartRateTraceExists() {
                self.chartTraces.append(self.heartRateTrace(activityRecord: activityRecord))
            }
            if activityRecord.powerTraceExists() {
                self.chartTraces.append(self.powerTrace(activityRecord: activityRecord))
            }
            if activityRecord.cadenceTraceExists() {
                self.chartTraces.append(self.cadenceTrace(activityRecord: activityRecord))
            }
            if activityRecord.altitudeTraceExists() {
                self.chartTraces.append(self.ascentTrace(activityRecord: activityRecord))
            }

            self.buildingChartTraces = false
        }
    }
    
    func buildMapTrace(recordID: CKRecord.ID) {
        
        buildingChartTraces = true
        recordFetchFailed = false
        
        dataCache.fetchRecord(recordID: recordID,
                              completionFunction: self.setMapTrace,
                              completionFailureFunction: self.fetchFailed)
        
    }
    

    
    func setMapTrace(activityRecord: ActivityRecord) {
        
        DispatchQueue.main.async {

            self.routeCoordinates = self.routeCoordinates(activityRecord: activityRecord)
            
            if self.routeCoordinates.count > 0 {
                let latitudes = self.routeCoordinates.map({$0.latitude})
                let longitudes = self.routeCoordinates.map({$0.longitude})
                let midLatitude = (latitudes.max()! + latitudes.min()!) / 2
                let midLongitude = (longitudes.max()! + longitudes.min()!) / 2
                let routeCenter = CLLocationCoordinate2D(latitude: midLatitude,
                                                          longitude: midLongitude)
                let latitudeDelta = latitudes.max()! - latitudes.min()!
                let longitudeDelta = longitudes.max()! - longitudes.min()!

                self.cameraPos = MapCameraPosition.region(
                    MKCoordinateRegion(center: routeCenter,
                                       span: MKCoordinateSpan(latitudeDelta: latitudeDelta,  longitudeDelta: longitudeDelta)))
            }
            
            self.buildingChartTraces = false
        }
    }
    
    func fetchFailed() {
        
        DispatchQueue.main.async {
            
            self.recordFetchFailed = true
            self.buildingChartTraces = false

        }

    }

}
