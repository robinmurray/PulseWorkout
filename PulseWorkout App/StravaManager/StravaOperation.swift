//
//  StravaOperation.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 22/01/2025.
//

import Foundation
import StravaSwift
import os


typealias StravaActivity = Activity

/** The default token delegate. You should replace this with something that persists the token (e.g. to NSUserDefaults)
**/
class PersistentTokenDelegate: TokenDelegate {
   fileprivate var token: OAuthToken?

//    public let accessToken: String?
//    public let refreshToken: String?
//    public let expiresAt : Int?
    
    let tokenKey: String = "StravaOAUTHToken"
   /**
    Retrieves the token

    - Returns: a optional OAuthToken
    **/
   open func get() -> OAuthToken? {
       let tokenDict:[String:Any?] =  UserDefaults.standard.dictionary(forKey: tokenKey) ?? [:]

       guard let accessToken = tokenDict["accessToken"] as? String?,
             let refreshToken = tokenDict["refreshToken"] as? String?,
             let expiresAt = tokenDict["expiresAt"] as? Int? else {return nil}

       self.token = OAuthToken(access: accessToken, refresh: refreshToken, expiry: expiresAt)
       return token
   }

   /**
    Stores the token internally (note that it is not persisted between app start ups)

    - Parameter token: an optional OAuthToken
    **/
   open func set(_ token: OAuthToken?) {
       let tokenDict:[String:Any?] = ["accessToken" : token?.accessToken as Any?,
                                    "refreshToken": token?.refreshToken as Any?,
                                    "expiresAt" : token?.expiresAt as Any?]

       UserDefaults.standard.set(tokenDict, forKey: tokenKey)
       self.token = token
   }
}



class StravaOperation: NSObject, ObservableObject {
    
    @Published var stravaBusy: Bool
    var forceReauth: Bool
    var forceRefresh: Bool
    
    let logger = Logger(subsystem: "com.RMurray.PulseWorkout",
                        category: "stravaOperation")
    
    init(forceReauth: Bool = false, forceRefresh: Bool = false) {
        self.forceReauth = forceReauth
        self.forceRefresh = forceRefresh
        self.stravaBusy = false
    }
 
    func stravaBusyStatus(_ busy: Bool) {
        DispatchQueue.main.async {
            self.stravaBusy = busy
        }
    }
    
    func authenticate(completionHandler: @escaping () -> Void, failureCompletionHandler: @escaping () -> Void) {
        self.stravaBusyStatus(true)

        StravaClient.sharedInstance.authorize() { [weak self] (result: Result<OAuthToken, Error>) in

            guard let self = self else { return }

            self.didAuthenticate(result: result, completionHandler: completionHandler, failureCompletionHandler: failureCompletionHandler)
            
        }
    }
    
    func refreshToken(completionHandler: @escaping () -> Void, failureCompletionHandler: @escaping () -> Void) {
        
        StravaClient.sharedInstance.refreshAccessToken(StravaClient.sharedInstance.token!.refreshToken!) { [weak self] (result: Result<OAuthToken, Error>) in
            guard let self = self else { return }
            self.didAuthenticate(result: result, completionHandler: completionHandler, failureCompletionHandler: failureCompletionHandler)

        }
    }

    
    private func didAuthenticate(result: Result<OAuthToken, Error>, completionHandler: @escaping () -> Void, failureCompletionHandler: @escaping () -> Void) {
        
        self.stravaBusyStatus(false)
        
        switch result {
            case .success(let token):
//                self.token = token
                self.logger.info("Authentication Success! token : \(token)")
                let expirySeconds = token.expiresAt ?? 0
                let expiryDate = Date(timeIntervalSince1970: TimeInterval(expirySeconds))
                self.logger.info("Token expiry : \(expiryDate)")
                completionHandler()
            
            case .failure(let error):
                self.logger.error("Authentication Error \(error)")
                failureCompletionHandler()
        }
    }
    
    func validToken(execFunction: @escaping () -> Void, failureCompletionHandler: @escaping () -> Void) -> Bool {
        
        if let authToken = StravaClient.sharedInstance.token {
            if (authToken.expiresAt ?? 0) < Int(Date().timeIntervalSince1970) {
                logger.info("Refresh Token")
                refreshToken(completionHandler: execFunction, failureCompletionHandler: failureCompletionHandler)
                return false
            }
        } else {
            authenticate(completionHandler: execFunction, failureCompletionHandler: failureCompletionHandler)
            return false
        }
        
        if forceReauth {
            forceReauth = false
            authenticate(completionHandler: execFunction, failureCompletionHandler: failureCompletionHandler)
            return false
        }

        if forceRefresh {
            forceRefresh = false
            refreshToken(completionHandler: execFunction, failureCompletionHandler: failureCompletionHandler)
            return false
        }
        return true
    }

}



