//
//  ActivityRecord_CSVExport.swift
//  PulseWorkout
//
//  Created by Robin Murray on 04/11/2025.
//

import Foundation
import CoreTransferable


struct csvExportFile: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {

  
        FileRepresentation(exportedContentType: .commaSeparatedText,
                           shouldAllowToOpenInPlace: false,
                           exporting:
                            { csvFile in
//                                let fileURL = CacheURL(fileName: "activityCache.act")!
            return SentTransferredFile(csvFile.url)
                            }
                        )
        
    }
}

/// Extension for Saving / Sharing activity data as csv file
extension ActivityRecord {
    
    func escapeCSV(_ input: String) -> String {
        let needsQuoting = input.contains(",") || input.contains("\"") || input.contains("\n")
        if !needsQuoting {
            return input
        }
        let escapedInput = input.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escapedInput)\""
    }
    
    func asCSVExportFile(dataCache: DataCache) -> csvExportFile {
        
        let fileURL = CacheURL(fileName: "ActivityRecord.csv")!
        
        var content = "Time, HeartRate, Latitude, Longitude, AltitudeMeters, DistanceMeters, Cadence, Speed, Watts\n"
        
        if let cachedRecord = dataCache.fullActivityRecordCache.get(recordID: recordID) {
            for trackPoint in cachedRecord.trackPoints {
                content += trackPoint.asCSV()
            }
        }

        do {
            try content.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
        
        return csvExportFile(url: fileURL)
    }
}
