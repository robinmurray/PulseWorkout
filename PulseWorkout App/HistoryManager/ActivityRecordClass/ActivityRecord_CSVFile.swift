//
//  ActivityRecord_CSVFile.swift
//  PulseWorkout
//
//  Created by Robin Murray on 04/11/2025.
//

import Foundation
import CoreTransferable
import UniformTypeIdentifiers
import CloudKit

enum DataCacheFetchError: Error {
    case runtimeError(String)
}

struct ActivityRecordCSVFile: Transferable {
    let activityRecordID: CKRecord.ID
    let dataCache: DataCache
    
    static var transferRepresentation: some TransferRepresentation {

  
        FileRepresentation(
            exportedContentType: .data,
            shouldAllowToOpenInPlace: false,
            exporting:
                { item in
                    do {
                        let url = try await getCSVFile(item: item)
                        return SentTransferredFile(url)
                    } catch let error {
                        throw error
                    }
            
                }
            )
    }
    
    /// async function to fetch record if necessary and build csv file - returns as URL
    static func getCSVFile(item: Self) async throws -> URL {
        
        do {
            let cachedRecord = try await item.dataCache.fullActivityRecordCache.asyncGet(recordID: item.activityRecordID)
            return try cachedRecord.asCSVFile()
        } catch let error {
            throw error
        }
        
    }
}


/// Extension for Saving / Sharing activity data as csv file
extension ActivityRecord {
    
    /// return URL to csv file representing all track points
    func asCSVFile() throws -> URL {
        
        let fileURL = CacheURL(fileName: "ActivityRecord.csv")!
        
        var content = "Time, HeartRate, Latitude, Longitude, AltitudeMeters, DistanceMeters, Cadence, Speed, Watts\n"
        
        for trackPoint in trackPoints {
            content += trackPoint.asCSV()
        }


        do {
            try content.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
        } catch let error {
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
            throw error
        }
        
        return fileURL
    }
    
}
