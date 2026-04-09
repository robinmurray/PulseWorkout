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

                self.logger.info("uploadFile completion with status: \(String(describing: uploadStatus))")
                
                guard let uploadStatus = uploadStatus else {
                    self.logger.error("Error : No Upload status in upload")
                    self.activityRecord.setStravaSaveStatus(StravaSaveStatus.notSaved)
                    self.failureCompletionHandler()
                    return }
                
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
    
    
    func parseDuplicateUpload(_ text: String) -> Int? {
        
        self.logger.info("Parsing \(text) for duplicate error message")
        // Split at " duplicate of "
        let parts = text.components(separatedBy: " duplicate of ")
        guard parts.count == 2 else { return nil }
        let filename = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)

        let tail = parts[1]
        // Extract activity ID between "/activities/" and the next "'"
        guard let idRange = tail.range(of: "/activities/") else { return nil }
        let afterID = tail[idRange.upperBound...]
        guard let endID = afterID.firstIndex(of: "'") else { return nil }
        let activityIDString = String(afterID[..<endID])
        let activityID = Int(activityIDString)

        // Extract title between '>' and '</a>'
        guard let startTitle = tail.firstIndex(of: ">"),
              let endTitle = tail.range(of: "</a>")?.lowerBound else { return nil }
        let title = String(tail[tail.index(after: startTitle)..<endTitle])

        self.logger.info("Duplicate activityID : \(String(describing: activityID))")
        return activityID
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

            self.logger.info("Scheduling polling upload status : Count :: \(currentRetry)")
            
            // Poll for upload status...
            DispatchQueue.main.asyncAfter(deadline: .now() + PAUSE_TIME,
                                          qos: .userInitiated) {
                
                self.logger.info("Polling upload status : Count :: \(currentRetry)")
                
                StravaClient.sharedInstance.request(Router.uploads(id: uploadId), result: { /*[weak self]*/ (status: UploadStatus?) in
//                    guard let self = self else {
//                        print("No Self!")
//                        return
//                    }
                    
                    self.logger.info("upload status completion with status: \(String(describing: status))")
                    
                    guard let status = status else {
                        self.logger.error("Error : No Upload status in poll for upload")
                        self.pollUploadStatus(uploadId: uploadId, retryCount: retryCount, currentRetry: currentRetry + 1)
                        return
                    }
                    if let error = status.error {
                        self.logger.error("Upload failed with error : \(error)")
                        
                        if let activityID = self.parseDuplicateUpload(error) {
                            self.logger.info("Polling completed successfully :: retry count \(currentRetry) :: id \(activityID)")
                            self.activityRecord.stravaId = activityID
                            self.activityRecord.setStravaSaveStatus(StravaSaveStatus.gotStravaId)

                            StravaUpdateActivity(
                                activityRecord: self.activityRecord,
                                completionHandler: { _ in
                                    self.activityRecord.setStravaSaveStatus(StravaSaveStatus.saved)

                                    self.completionHandler(activityID)
                                },
                                failureCompletionHandler: self.failureCompletionHandler ).execute()
     
                            return
                        }
                        
                        self.pollUploadStatus(uploadId: uploadId, retryCount: retryCount, currentRetry: currentRetry + 1)
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
