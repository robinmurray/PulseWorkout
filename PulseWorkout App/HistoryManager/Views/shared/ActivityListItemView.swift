//
//  ActivityListItemView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 30/06/2023.
//

import SwiftUI

struct ActivityListItemView: View {
    
    @ObservedObject var activityRecord: ActivityRecord
    var dataCache: DataCache
    
    
    var body: some View {
        VStack {

            HStack {

                Text(activityRecord.name)
                    .foregroundStyle(.yellow)
                    .multilineTextAlignment(.leading)
                #if os(iOS)
                    .fontWeight(.bold)
                #endif
                Spacer()
                HStack {
                    if activityRecord.toSavePublished {
                        Image(systemName: "icloud.slash.fill").foregroundColor(.red)
                    }
                    if activityRecord.stravaSaveStatus == StravaSaveStatus.saved.rawValue {
                        Image("StravaIcon").resizable().frame(width: 30, height: 30)
                    }
                    
                }

            }
            
            HStack {
                Text(activityRecord.startDateLocal.formatted(
                    Date.FormatStyle()
                        .day(.twoDigits)
                        .month(.abbreviated)
                        .hour(.defaultDigits(amPM: .omitted))
                        .minute(.twoDigits)
                        .hour(.conversationalDefaultDigits(amPM: .abbreviated))
                ))
                Spacer()
            }

        }
        
    }

}


struct ActivityListItemView_Previews: PreviewProvider {
    
    static var dataCache = DataCache()
    static var activityRecord = ActivityRecord()
    
    static var previews: some View {
        ActivityListItemView(activityRecord: activityRecord,
                             dataCache: dataCache)
    }
}

