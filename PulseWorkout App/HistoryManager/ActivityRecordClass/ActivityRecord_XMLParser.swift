//
//  ActivityRecord_XMLParser.swift
//  PulseWorkout
//
//  Created by Robin Murray on 26/02/2025.
//

import Foundation


extension ActivityRecord: XMLParserDelegate {


    func parserDidStartDocument(_ parser: XMLParser) {
        print("Started parsing document")
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        print("Ended parsing document : \(trackPoints.count) trackpoints created")
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        tagPath.append(elementName)

        switch elementName {
        case "Trackpoint":
            parsedTime = nil
            heartRate = nil
            cadence = nil
            watts = nil
            speed = nil
            latitude = nil
            longitude = nil
            totalAscent = nil
            totalDescent = nil
            altitudeMeters = nil
            distanceMeters = 0
            break

        default:
            // Do Nothing!
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        tagPath.removeLast()

        switch elementName {
        case "Trackpoint":
            if parsedTime != nil {
                trackPoints.append(TrackPoint(time: parsedTime!,
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
            }
            break

        default:
            // Do Nothing!
            break
        }

    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {

        switch tagPath.joined(separator: "/") {
        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/Time":
            // trackPointNode.addValue(name: "Time", value: time.formatted(Date.ISO8601FormatStyle().dateSeparator(.dash)))
//            self.logger.info("* Time : \(string)")
            let dateFormatter = ISO8601DateFormatter ()
            parsedTime = dateFormatter.date(from: string)

//            self.logger.info("* parsedTime : \(self.parsedTime?.timeIntervalSince1970 ?? 0)")

            break

        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/DistanceMeters":
            // trackPointNode.addValue(name: "DistanceMeters", value: String(Int(distanceMeters!)))
//            self.logger.info("* DistanceMeters : \(string)")
            distanceMeters = Double(string) ?? 0
            break

        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/Cadence":
            // trackPointNode.addValue(name: "Cadence", value: String(cadence!))
//            self.logger.info("* Cadence : \(string)")
            cadence = Int(string)
            break

        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/Position/LongitudeDegrees":
//            self.logger.info("* LongitudeDegrees : \(string)")
            longitude = Double(string)
            break

        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/Position/LatitudeDegrees":
//            self.logger.info("* LatitudeDegrees : \(string)")
            latitude = Double(string)
            break

        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/AltitudeMeters":
            // IS ALTITUDE INTERGER OR NOT!!??
            // trackPointNode.addValue(name: "AltitudeMeters", value: String(format: "%.1f", altitudeMeters!))
//            self.logger.info("* AltitudeMeters : \(string)")
            altitudeMeters = Double(string)
            break

        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/Extensions/TPX/Speed":
            // tpxNode.addValue(name: "Speed", value: String(format: "%.1f", speed!))
//            self.logger.info("* Speed : \(string)")
            speed = Double(string)
            break

        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/Extensions/TPX/Watts":
            // tpxNode.addValue(name: "Watts", value: String(watts!))
//            self.logger.info("* Watts : \(string)")
            watts = Int(string)
            break

        case "TrainingCenterDatabase/Activities/Activity/Lap/Track/Trackpoint/HeartRateBpm/Value":
              // HRNode.addValue(name: "Value", value: String(Int(heartRate!)))
//            self.logger.info("* HeartRateBpm : \(string)")
            heartRate = Double(string)
            break


        default:
            // Do Nothing!
            break
        }
    }

}
