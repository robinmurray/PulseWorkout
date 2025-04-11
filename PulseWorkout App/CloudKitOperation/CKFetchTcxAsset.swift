//
//  CKFetchTcxAsset.swift
//  PulseWorkout
//
//  Created by Robin Murray on 11/04/2025.
//

import Foundation
import CloudKit


class CKFetchTcxAssetOperation: CloudKitOperation {
    
    var recordID: CKRecord.ID
    var completionHandler: (Data) -> Void
    var failureCompletionHandler: () -> Void
    
    init(recordID: CKRecord.ID,
         completionHandler: @escaping (Data) -> Void,
         failureCompletionHandler: @escaping () -> Void = { } ) {

        self.recordID = recordID
        self.completionHandler = completionHandler
        self.failureCompletionHandler = failureCompletionHandler
        
        super.init()
    }
    
    func execute() {
        
        CKFetchRecordOperation(recordID: self.recordID,
                               completionFunction: fetchAsset,
                               completionFailureFunction: self.failureCompletionHandler).execute()
        
    }
    
    func fetchAsset(record: CKRecord) {
        
        if record["tcx"] != nil {
            self.logger.info("Got tcx asset")
            let asset = record["tcx"]! as CKAsset
            let fileURL = asset.fileURL!
            
            do {
                let tcxgzData = try Data(contentsOf: fileURL)
                self.logger.log("Got tcx gz data of size \(tcxgzData.count)")
                self.completionHandler(tcxgzData)

                
            } catch {
                self.logger.error("Can't get data at url:\(fileURL)")
                self.failureCompletionHandler()
            }
        }
        else {
            self.logger.info("No tcx data retrieved")
            self.failureCompletionHandler()
        }
    }
}


