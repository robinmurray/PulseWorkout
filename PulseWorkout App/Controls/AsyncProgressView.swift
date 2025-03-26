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
                            Text(asyncProgress.message!).lineLimit(1)
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
                                         total: asyncProgress.maxStatus ?? 1).lineLimit(1)
                            Text(asyncProgress.message ?? "").lineLimit(1)

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
                                         total: asyncProgress.maxStatus ?? 1).lineLimit(1)

                        }

                    }
                    
                }
                
            }
            .padding([.leading, .trailing], 10)
            .padding([.top, .bottom], 5)
            .background(Color.gray)
            .cornerRadius(15)
            .opacity(0.95)
            
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
    let _ = asyncProgressIndefinite.majorIncrement(message: "Step 1, very very very very very very very very long text")
    let asyncProgressMixed = AsyncProgress()
    let _ = asyncProgressMixed.start(asyncProgressModel: .mixed,
                                     title: "A task with mix of known & unkown",
                                     maxStatus: 10)
    let _ = asyncProgressMixed.majorIncrement(message: "Step 1 very very very very very very very very long text")
    VStack {
//        OutsideView()
        AsyncProgressView(asyncProgress: asyncProgressDefinite)
        Divider()
        AsyncProgressView(asyncProgress: asyncProgressIndefinite)
        Divider()
        AsyncProgressView(asyncProgress: asyncProgressMixed)
    }
    
}
