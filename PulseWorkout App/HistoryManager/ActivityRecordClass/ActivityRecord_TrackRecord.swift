//
//  ActivityRecord_TrackRecord.swift
//  PulseWorkout
//
//  Created by Robin Murray on 26/02/2025.
//

import Foundation


/// Extension for managing track points within ActivityRecord
extension ActivityRecord {

    /// Copy current values of instantaeous data fields to trackpoint and create trackpoint record
    /// Perform incremental analysis of data
    func addTrackPoint(trackPointTime: Date = Date()) {

        trackPoints.append(TrackPoint(time: trackPointTime,
                                      heartRate: heartRate,
                                      latitude: latitude,
                                      longitude: longitude,
                                      altitudeMeters: altitudeMeters,
                                      distanceMeters: distanceMeters,
                                      cadence: cadence,
                                      speed: speed,
                                      watts: watts
                                     )
                            )
        if !(isPaused && !settingsManager.aveHRPaused) {
            heartRateAnalysis.add(heartRate)
        }

        cadenceAnalysis.add(cadence == nil ? nil : Double(cadence!), includeZeros: settingsManager.aveCadenceZeros)
        powerAnalysis.add(cadence == nil ? nil : Double(watts!), includeZeros: settingsManager.avePowerZeros)

        averageHeartRate = heartRateAnalysis.average
        averageCadence = Int(cadenceAnalysis.average)
        averagePower = Int(powerAnalysis.average)

        TSSSummable = (TSSSummable ?? 0) + incrementalTSSSummable(watts: watts, seconds: ACTIVITY_RECORDING_INTERVAL)

    }


    ///
    func trackRecordXML() -> XMLDocument {

        let tcxXMLDoc = XMLDocument()

        tcxXMLDoc.addProlog(prolog: "xml version=\"1.0\" encoding=\"UTF-8\"")
        tcxXMLDoc.addComment(comment: "Written by PulseWorkout")

        let tcxNode = tcxXMLDoc.addNode(name: "TrainingCenterDatabase",
                                        attributes: ["xsi:schemaLocation" : "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd",
                                                     "xmlns:ns5" : "http://www.garmin.com/xmlschemas/ActivityGoals/v1",
                                                     "xmlns:ns3" : "http://www.garmin.com/xmlschemas/ActivityExtension/v2",
                                                     "xmlns:ns2" : "http://www.garmin.com/xmlschemas/UserProfile/v2",
                                                     "xmlns" : "http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2",
                                                     "xmlns:xsi" : "http://www.w3.org/2001/XMLSchema-instance"
                                                    ])
        let activitiesNode = tcxNode.addNode(name: "Activities")
        let activityNode = activitiesNode.addNode(name: "Activity", attributes: ["Sport" : "Biking"]) // FIX!!
        activityNode.addValue(name: "Id", value: startDate.formatted(Date.ISO8601FormatStyle().dateSeparator(.dash)))
        let lapNode = activityNode.addNode(name: "Lap", attributes: ["StartTime" : startDate.formatted(Date.ISO8601FormatStyle().dateSeparator(.dash))])
        lapNode.addValue(name: "TotalTimeSeconds", value: String(format: "%.1f", elapsedTime))
        lapNode.addValue(name: "DistanceMeters", value: String(format: "%.1f", distanceMeters))

        /// USE Cadence for average cadence, probably extension for power...
        let aveHRNode = lapNode.addNode(name: "AverageHeartRate")
        aveHRNode.addValue(name: "Value", value: String(Int(averageHeartRate)))
        lapNode.addValue(name: "TriggerMethod", value: "Manual")

        let trackNode = lapNode.addNode(name: "Track")
        for trackPoint in trackPoints {
            trackPoint.addXMLtoNode(node: trackNode)
        }

        return tcxXMLDoc

    }

    func saveTrackRecord() -> Bool {

        // get files for gzipped tcx file
        guard let gzFile = tcxFileName else { return false }
        guard let gzURL = CacheURL(fileName: gzFile) else { return false }

        logger.debug("testing file at \(gzURL.path)")
        if FileManager.default.fileExists(atPath: gzURL.path) {
            return true
        }
        logger.debug("file not found!")

        do {

            guard let tcxData = trackRecordXML().serialize().data(using: .utf8) else {return false}

            let compressedData: Data = try tcxData.gzipped()
            try compressedData.write(to: gzURL)
            return true
        }
        catch {
//            error as any Error
            logger.error("error \(error)")
            return false
        }

    }

    /// Remove temporary .tcx file
    func deleteTrackRecord() {
        guard let tFile = tcxFileName else { return }
        guard let tURL = CacheURL(fileName: tFile) else { return }

        do {
            try FileManager.default.removeItem(at: tURL)
                logger.debug("tcx has been deleted")
        } catch {
            logger.error("error \(error)")
        }
    }

}

