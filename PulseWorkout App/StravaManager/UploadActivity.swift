//
//  UploadActivity.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 21/03/2025.
//

import Foundation
import StravaSwift



/// Upload strava activity - this is asynchronous - just get an uploadId as completion. Use this poll for actual strava activity...
class StravaUploadActivity: StravaOperation {

    var activityRecord: ActivityRecord
    var completionHandler: (Int) -> Void
    var failureCompletionHandler: () -> Void

    
    init(activityRecord: ActivityRecord,
         completionHandler: @escaping (Int) -> Void,
         failureCompletionHandler: @escaping () -> Void = { },
         forceReauth: Bool = false,
         forceRefresh: Bool = false) {
        
        self.activityRecord = activityRecord
        self.completionHandler = completionHandler
        self.failureCompletionHandler = failureCompletionHandler
        

        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)


    }
    
    
    /// If tcx asset alreday loaded use it, else fetch from cloudkit and call upload on completion
    func execute() {
        
        activityRecord.setStravaSaveStatus(StravaSaveStatus.saving)
        
        if let asset = activityRecord.tcxAsset {

            let fileURL = asset.fileURL!
            
            do {
                let tcxgzData = try Data(contentsOf: fileURL)
                self.logger.log("Got tcx data of size \(tcxgzData.count)")
                
                upload(tcxgzData: tcxgzData)

            } catch {
                self.logger.error("Can't get data at url:\(fileURL)")
                activityRecord.setStravaSaveStatus(StravaSaveStatus.notSaved)
                self.failureCompletionHandler()
            }
        } else {
            CKFetchTcxAssetOperation(
                recordID: activityRecord.recordID,
                completionHandler: upload,
                failureCompletionHandler: {
                self.activityRecord.setStravaSaveStatus(StravaSaveStatus.notSaved)
                self.failureCompletionHandler()
            }
            ).execute()
        }

    }

    /// Perform upload to strava - call configured completion handlers on success / failure
    func upload(tcxgzData: Data) {
        
        let uploadData = UploadData(activityType: ActivityType(rawValue: activityRecord.stravaType) ?? .ride,
                                    name: activityRecord.name,
                                    description: nil,
                                    private: false,
                                    trainer: nil,
                                    externalId: activityRecord.recordID.recordName,
                                    dataType: .tcxGz,
                                    file: tcxgzData)


        if validToken(execFunction: self.execute, failureCompletionHandler: failureCompletionHandler) {

            StravaClient.sharedInstance.upload(Router.uploadFile(upload: uploadData), upload: uploadData, result: { [weak self] (uploadStatus: UploadStatus?) in

                guard let self = self else { return }
                self.stravaBusyStatus(false)

                guard let uploadStatus = uploadStatus else {
                    self.logger.error("Error : No Upload status")
                    self.activityRecord.setStravaSaveStatus(StravaSaveStatus.notSaved)
                    self.failureCompletionHandler()
                    return }
                
                self.logger.info("Upload Status \(uploadStatus)")

                activityRecord.stravaUploadId = uploadStatus.id
                activityRecord.setStravaSaveStatus(StravaSaveStatus.uploaded)
                
                // Now get the stravaId and then update the Strava record if successful
                GetStravaIdFromStravaUploadId(
                    activityRecord: self.activityRecord,
                    completionHandler: self.completionHandler,
                    failureCompletionHandler: self.failureCompletionHandler).execute()
                                

            }, failure: { (error: NSError) in
                self.stravaBusyStatus(false)
                self.logger.error("Error : \(error.localizedDescription) :: \(error)")
                if error.code == 429 {
                    self.logger.error("Strava API limit exceeded")
                }
                self.activityRecord.setStravaSaveStatus(StravaSaveStatus.notSaved)
                self.failureCompletionHandler()
            })
        }
    }
}



/// Get stravaId from UploadId...
/// If succesful, update strava record with details from activityRecord
class GetStravaIdFromStravaUploadId: StravaOperation {
    
    var activityRecord: ActivityRecord
    var completionHandler: (Int) -> Void
    var failureCompletionHandler: () -> Void
    
    
    init(activityRecord: ActivityRecord,
         completionHandler: @escaping (Int) -> Void,
         failureCompletionHandler: @escaping () -> Void = { },
         forceReauth: Bool = false,
         forceRefresh: Bool = false) {
        
        self.activityRecord = activityRecord
        self.completionHandler = completionHandler
        self.failureCompletionHandler = failureCompletionHandler
        
        
        super.init(forceReauth: forceReauth, forceRefresh: forceRefresh)
        
        
    }
  
    func execute() {
        
        // if no uploadId, then something's wrong!!
        if activityRecord.stravaUploadId == nil {
            self.logger.error("Error : No Upload Id")
            self.failureCompletionHandler()
            return
        }
        
        // if already have a stravaId, then something wrong really, but contine as if fetched
        if let stravaId = activityRecord.stravaId {
            self.activityRecord.setStravaSaveStatus(StravaSaveStatus.gotStravaId)
            StravaUpdateActivity(
                activityRecord: self.activityRecord,
                completionHandler: { _ in
                    self.activityRecord.setStravaSaveStatus(StravaSaveStatus.saved)
                    self.completionHandler(stravaId)
                },
                failureCompletionHandler: self.failureCompletionHandler ).execute()
            return
            
        }
        
        // We (correctly) have an uploadId and no stravaId...
        pollUploadStatus(uploadId: activityRecord.stravaUploadId!,
                         retryCount: 5,
                         currentRetry: 1)
        
    }
    
    
    /// Poll upload status to get StravaId
    /// If successful then attempt to update the Strava record
    func pollUploadStatus(uploadId: Int, retryCount: Int, currentRetry: Int) {
        
        let PAUSE_TIME: TimeInterval = 3 * Double(currentRetry)  // Delay between attempts as Strava processes the upload..
        
        if currentRetry >= retryCount {
            self.logger.error("Polling complete without success :: \(currentRetry)")
            self.failureCompletionHandler()
        }
        
        else {

            // Poll for upload status...
            DispatchQueue.main.asyncAfter(deadline: .now() + PAUSE_TIME) {
                
                self.logger.info("Polling upload status : Count :: \(currentRetry)")
                
                StravaClient.sharedInstance.request(Router.uploads(id: uploadId), result: { /*[weak self]*/ (status: UploadStatus?) in
//                    guard let self = self else {
//                        print("No Self!")
//                        return
//                    }
                    guard let status = status else {
                        self.logger.error("Error : No Upload status")
                        self.failureCompletionHandler()
                        return
                    }
                    if let error = status.error {
                        self.logger.error("Upload failed with error : \(error)")
                        self.failureCompletionHandler()
                        return
                    } else if let stravaId = status.activityId {
                        // We have a valid activityID so the upload is considered complete.
                        // However, note that segment processing can continue for quite a while.
                        self.logger.info("Polling completed successfully :: retry count \(currentRetry) :: id \(stravaId)")
                        self.activityRecord.stravaId = stravaId
                        self.activityRecord.setStravaSaveStatus(StravaSaveStatus.gotStravaId)

                        StravaUpdateActivity(
                            activityRecord: self.activityRecord,
                            completionHandler: { _ in
                                self.activityRecord.setStravaSaveStatus(StravaSaveStatus.saved)

                                self.completionHandler(stravaId)
                            },
                            failureCompletionHandler: self.failureCompletionHandler ).execute()
                    } else {
                        // Start another timer
                        self.logger.info("Trying again...")
                        self.pollUploadStatus(uploadId: uploadId, retryCount: retryCount, currentRetry: currentRetry + 1)
                    }
                }, failure: { (error: NSError) in
                    debugPrint(error)
                })
                
                
            }
        }

    }
    
}
