//
//  AsyncProgressView.swift
//  PulseWorkout
//
//  Created by Robin Murray on 24/03/2025.
//

import SwiftUI

struct AsyncProgressView: View {
    
    @StateObject var asyncProgress: AsyncProgress

    var body: some View {
        
        HStack{
            Spacer(minLength: 10)
            VStack {
                switch asyncProgress.asyncProgressModel {
                case .indefinite:
                    VStack {
                        HStack{
                            Spacer()
                        }
                        
                        ProgressView(asyncProgress.title ?? "")
                        if asyncProgress.message != nil {
                            Text(asyncProgress.message!)
                        }
                        
                    }
                    
                case .definite:
                    VStack {
                        HStack {
                            Spacer()
                        }
                        VStack {

                            ProgressView(asyncProgress.title ?? "",
                                         value:  asyncProgress.status,
                                         total: asyncProgress.maxStatus ?? 1)
                            Text(asyncProgress.message ?? "")

                        }
                    }
                    
                case .mixed:
                    VStack {
                        HStack {
                            Spacer()
                        }
                        VStack{
                            ProgressView(asyncProgress.title ?? "")
                            ProgressView(asyncProgress.message ?? "",
                                         value:  asyncProgress.status,
                                         total: asyncProgress.maxStatus ?? 1)

                        }

                    }
                    
                }
                
            }
            .padding([.leading, .trailing], 10)
            .padding([.top, .bottom], 5)
            .background(Color.secondary.opacity(0.8))
            .cornerRadius(15)
            
            Spacer(minLength: 10)
        }


    }
}

#Preview {
    let asyncProgressDefinite = AsyncProgress()
    let _ = asyncProgressDefinite.start(asyncProgressModel: .definite,
                                        title: "A task with known length",
                                        maxStatus: 10)
    let _ = asyncProgressDefinite.majorIncrement(message: "Step 1")
    let asyncProgressIndefinite = AsyncProgress()
    let _ = asyncProgressIndefinite.start(asyncProgressModel: .indefinite,
                                          title: "A task with unknown length")
    let _ = asyncProgressIndefinite.majorIncrement(message: "Step 1")
    let asyncProgressMixed = AsyncProgress()
    let _ = asyncProgressMixed.start(asyncProgressModel: .mixed,
                                     title: "A task with mix of known & unkown",
                                     maxStatus: 10)
    let _ = asyncProgressMixed.majorIncrement(message: "Step 1")
    VStack {
//        OutsideView()
        AsyncProgressView(asyncProgress: asyncProgressDefinite)
        Divider()
        AsyncProgressView(asyncProgress: asyncProgressIndefinite)
        Divider()
        AsyncProgressView(asyncProgress: asyncProgressMixed)
    }
    
}
