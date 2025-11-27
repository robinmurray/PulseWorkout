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

                VStack {
                    HStack {
                        Text(activityRecord.name)
                            .foregroundStyle(.yellow)
                            .multilineTextAlignment(.leading)
    #if os(iOS)
                            .fontWeight(.bold)
    #endif
    #if os(watchOS)
                            .lineLimit(3)
    #endif

                        Spacer()
                        LinkToStravaView(activityRecord: activityRecord)
                        
                    }

                    HStack {
                        Text(startDateLocalFormatter(startDateLocal: activityRecord.startDateLocal))
                        
                        Spacer()
                    }

                }
                Spacer()
                if activityRecord.toSavePublished {
                    VStack {
                        Image(systemName: "icloud.slash.fill").foregroundColor(.red)
                        Spacer()
                    }

                }


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

