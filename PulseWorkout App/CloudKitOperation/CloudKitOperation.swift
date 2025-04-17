//
//  CloudKitOperation.swift
//  PulseWorkout
//
//  Created by Robin Murray on 08/04/2025.
//

import Foundation
import CloudKit
import os



class CloudKitOperation: NSObject {

    var containerName: String
    var container: CKContainer
    var database: CKDatabase
    var zoneName: String
    var zoneID: CKRecordZone.ID
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "CloudKitOperation")
    
    override init() {
        containerName = "iCloud.MurrayNet.Aleph"
        container = CKContainer(identifier: containerName)
        database = container.privateCloudDatabase
        zoneName = "Aleph_Zone"
        zoneID = CKRecordZone.ID(zoneName: zoneName)
        
        super.init()
    }

    
    private func createCKZoneIfNeeded(zoneID: CKRecordZone.ID) async throws {

        guard !UserDefaults.standard.bool(forKey: "zoneCreated") else {
            return
        }

        logger.log("creating zone")
        let newZone = CKRecordZone(zoneID: zoneID)
        _ = try await database.modifyRecordZones(saving: [newZone], deleting: [])

        UserDefaults.standard.set(true, forKey: "zoneCreated")
    }
 
    
    /// Function to create a new recordID in correct zone, given a record name
    func getCKRecordID(recordID: UUID?) -> CKRecord.ID {
        
        let recordName: String = recordID?.uuidString ?? CKRecord.ID().recordName
        
        return CKRecord.ID(recordName: recordName, zoneID: zoneID)
    }

    
    /// Function to create a new recordID in correct zone from scratch
    func getCKRecordID() -> CKRecord.ID {
        let recordName = CKRecord.ID().recordName
        return CKRecord.ID(recordName: recordName, zoneID: zoneID)
    }

    /// Function to create a new recordID in correct zone from a given fixed name
    func getCKRecordID(recordName: String) -> CKRecord.ID {

        return CKRecord.ID(recordName: recordName, zoneID: zoneID)
    }
    
}

