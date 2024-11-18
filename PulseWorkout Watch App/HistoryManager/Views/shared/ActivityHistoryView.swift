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
        
        NavigationStack {
            #if os(iOS)
            ActivityHistoryHeaderView()
            #endif
            List {
                ForEach(dataCache.UIRecordSet) {activityRecord in
                    VStack {
                        NavigationLink {
                            ActivityDetailView(activityRecord: activityRecord,
                                               dataCache: dataCache)
                        } label : {
                            ActivityListItemView(activityRecord: activityRecord,
                                                 dataCache: dataCache)
                        }
                        .swipeActions {
                            Button(role:.destructive) {
                                dataCache.delete(recordID:
                                    activityRecord.recordID)
                            } label: {
                                Label("Delete", systemImage: "xmark.bin")
                            }
                                
                        }

                        #if os(iOS)
                        ActivityListItemExtensionView(activityRecord: activityRecord, dataCache: dataCache)
                        #endif
                    }

                }
            }
            #if os (iOS)
            .listStyle(.grouped)
            #endif

        #if os(watchOS)
            .navigationTitle {
                HStack {
                    Image(systemName: "book.circle")
                        .foregroundColor(Color.black)
                        .background(Color.yellow)
                        .clipShape(Circle())
                    Text("History")
                        .foregroundColor(Color.yellow)
                }
            }
        #endif
        }
        


    }
}

struct ActivityHistoryView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var dataCache = DataCache(settingsManager: settingsManager)
    static var activityRecord = ActivityRecord(settingsManager: settingsManager)
    
    init() {

        ActivityHistoryView_Previews.dataCache.UIRecordSet.append(ActivityHistoryView_Previews.activityRecord)

    }
    
    static var previews: some View {
        ActivityHistoryView(dataCache: dataCache)
    }
}
