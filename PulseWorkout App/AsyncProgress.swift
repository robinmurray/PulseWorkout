//
//  AsyncProgress.swift
//  PulseWorkout
//
//  Created by Robin Murray on 24/03/2025.
//

import Foundation

enum AsyncProgressModel {
    case indefinite     // unknown length - display spinner in progress view
    case definite       // known length - display progress bar
    case mixed          // overall uknown length, but composed of a series of known length steps - display both spinner and progress bar
}

class AsyncProgress: NSObject, ObservableObject {
    
    @Published var title: String?
    @Published var status: Double
    
    /// Boolean set to true / false in main async thread on start and completion
    @Published var displayProgressView: Bool
    @Published var message: String?
    

    var asyncProgressModel: AsyncProgressModel = .indefinite
    var maxStatus: Double?
    var step: Int
    var subStep: Int
    
    /// Boolean set to true / false immediately on start and completion
    var inProgress: Bool
    
    override init() {
        status = 0
        step = 0
        subStep = 0
        inProgress = false
        displayProgressView = false
        super.init()
    }
    
    
    private func calculateStatus() {

        let subStepStatus = 1 - (1 / (pow(2, subStep)))
        status = Double(step) + Double(truncating: NSDecimalNumber(decimal:subStepStatus))
        status = min(status, maxStatus ?? 1)
        
    }
    
    
    func start(asyncProgressModel: AsyncProgressModel, title: String? = nil, maxStatus: Double? = nil) {
        
        self.asyncProgressModel = asyncProgressModel
        self.maxStatus = maxStatus
        self.inProgress = true
        
        // Set published variables in main async thread
        DispatchQueue.main.async {
            self.status = 0
            self.displayProgressView = true
            self.message = nil
            self.title = title
            

        }

    }
    
    
    func majorIncrement(message: String? = nil) {
        DispatchQueue.main.async {
            self.step += 1
            self.subStep = 0
            self.calculateStatus()
            self.message = message
        }
    }

    
    func minorIncrement(message: String? = nil) {
        DispatchQueue.main.async {
            self.subStep += 1
            self.calculateStatus()
            self.message = message
        }
    }
    
    
    func set(message: String) {
        DispatchQueue.main.async {
            self.message = message
        }
    }
    
    
    func resetStatus(message: String? = nil) {
        
        set(newStatus: 0 , message: message)
        
    }
    
    
    func set(newStatus: Double, message: String? = nil) {
        DispatchQueue.main.async {
            self.status = newStatus
            self.message = message
        }
    }
    
    func complete() {
        
        self.inProgress = false
        
        DispatchQueue.main.async {
            self.displayProgressView = false
        }
    }
    
}
