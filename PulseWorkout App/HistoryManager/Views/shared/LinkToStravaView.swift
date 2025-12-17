//
//  LinkToStravaView.swift
//  PulseWorkout
//
//  Created by Robin Murray on 04/11/2025.
//

import SwiftUI

struct LinkToStravaView: View {
    
    @ObservedObject var activityRecord: ActivityRecord

#if os(iOS)
    func viewOnStrava(recordId: Int) {

        if let url = URL(string: "strava://activities/" + String(recordId)) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:])
            }
        }

    }
#endif
    
    var body: some View {
        if activityRecord.stravaSaveStatus == StravaSaveStatus.saved.rawValue {
            VStack {
#if os(iOS)
                if #available(iOS 26.0, *) {
                    Button(action: {
                        if let stravaId = activityRecord.stravaId {
                            viewOnStrava(recordId: stravaId)
                        }
                    }) {
                        Image("StravaIcon").resizable().frame(width: 30, height: 30)
                    }
                    .buttonStyle(.glass)
                    .glassEffect(.clear)
                } else {
                    // Fallback on earlier versions
                    Button(action: {
                        if let stravaId = activityRecord.stravaId {
                            viewOnStrava(recordId: stravaId)
                        }
                    }) {
                        Image("StravaIcon").resizable().frame(width: 30, height: 30)
                    }
                }
#endif
#if os(watchOS)
                Image("StravaIcon").resizable().frame(width: 20, height: 20)
#endif
//                Spacer()
            }
        
        } else {
            EmptyView()
        }
    }
}

#Preview {
    LinkToStravaView(activityRecord: ActivityRecord())
}
