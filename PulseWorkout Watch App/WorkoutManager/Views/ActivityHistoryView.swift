//
//  ActivityHistoryView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 30/06/2023.
//

import SwiftUI


struct ActivityHistoryView: View {
    
    @ObservedObject var dataCache: DataCache
    
 
    var body: some View {
        

 //       VStack {

            NavigationStack {
                List{
                    ForEach(dataCache.UIRecordSet) {activityRecord in
                        NavigationLink {
                            ActivityDetailView(activityRecord: activityRecord)
                        } label : {
                            ActivityListItemView(activityRecord: activityRecord)
                        }
                        .swipeActions {
                            Button(role:.destructive) {
                                dataCache.delete(recordID:
                                    activityRecord.recordID)
                            } label: {
                                Label("Delete", systemImage: "xmark.bin")
                            }
                                
                        }
                    }
                }
                    

            }
            .padding()
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
//        }

    }
}

struct ActivityHistoryView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var dataCache = DataCache()
    static var activityRecord = ActivityRecord(settingsManager: settingsManager)
    
    init() {
        ActivityHistoryView_Previews.dataCache.UIRecordSet.append(ActivityHistoryView_Previews.activityRecord)

    }
    
    static var previews: some View {
        ActivityHistoryView(dataCache: dataCache)
    }
}
