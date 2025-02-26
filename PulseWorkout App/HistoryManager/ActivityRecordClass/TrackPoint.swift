//
//  TrackPoint.swift
//  PulseWorkout
//
//  Created by Robin Murray on 26/02/2025.
//

import Foundation



struct TrackPoint {
    var time: Date
    var heartRate: Double?
    var latitude: Double?
    var longitude: Double?
    var altitudeMeters: Double?
    var distanceMeters: Double?
    var cadence: Int?
    var speed: Double?
    var watts: Int?


    func addXMLtoNode(node: XMLElement) {
        let trackPointNode = node.addNode(name: "Trackpoint")
        trackPointNode.addValue(name: "Time", value: time.formatted(Date.ISO8601FormatStyle().dateSeparator(.dash)))

        if ((latitude != nil) && (longitude != nil)) {
            let positionNode = trackPointNode.addNode(name: "Position")
            positionNode.addValue(name: "LatitudeDegrees", value: String(format: "%.7f", latitude!))
            positionNode.addValue(name: "LongitudeDegrees", value: String(format: "%.7f", longitude!))

        }
        if altitudeMeters != nil {
            trackPointNode.addValue(name: "AltitudeMeters", value: String(format: "%.1f", altitudeMeters!))
        }

        if heartRate != nil {
            let HRNode = trackPointNode.addNode(name: "HeartRateBpm")
            HRNode.addValue(name: "Value", value: String(Int(heartRate!)))
        }

        if distanceMeters != nil {
            trackPointNode.addValue(name: "DistanceMeters", value: String(Int(distanceMeters!)))
        }

        if cadence != nil {
            trackPointNode.addValue(name: "Cadence", value: String(cadence!))
        }

        if (speed != nil && (speed ?? -1) > 0) || watts != nil {
            let extNode = trackPointNode.addNode(name: "Extensions")
            let tpxNode = extNode.addNode(name: "TPX", attributes: ["xmlns" : "http://www.garmin.com/xmlschemas/ActivityExtension/v2"])
            if (speed != nil && (speed ?? -1) > 0) {
                tpxNode.addValue(name: "Speed", value: String(format: "%.1f", speed!))
            }
            if watts != nil {
                tpxNode.addValue(name: "Watts", value: String(watts!))
            }

        }

    }

}
