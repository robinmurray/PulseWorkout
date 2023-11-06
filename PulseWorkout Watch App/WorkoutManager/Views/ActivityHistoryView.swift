//
//  ActivityHistoryView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 30/06/2023.
//

import SwiftUI


struct ActivityHistoryView: View {
    
    @State var isBusy: Bool = false
//    var status: UILabel! = UILabel()
    @ObservedObject var activityDataManager: ActivityDataManager
    
 
    var body: some View {
        
        ZStack {
            VStack {

                NavigationStack {
                    List{
                        ForEach(activityDataManager.recordSet) {activityRecord in
                            NavigationLink {
                                ActivityDetailView(activityRecord: activityRecord)
                            } label : {
                                ActivityListItemView(activityRecord: activityRecord)
                            }
                            .swipeActions {
                                Button("Delete") {
                                    activityDataManager.delete(recordID: activityRecord.recordID)
                                }
                                .tint(.red)
                            }
                        }
                    }
                    

                }
                
            }
            .padding()

            if activityDataManager.isBusy {

                ProgressView()
                    .scaleEffect(2)
                

            }

    
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ActivityHistoryView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var activityDataManager = ActivityDataManager(settingsManager: settingsManager)
    static var activityRecord = ActivityRecord(settingsManager: settingsManager)
    
    init() {
        ActivityHistoryView_Previews.activityDataManager.recordSet.append(ActivityHistoryView_Previews.activityRecord)

    }
    
    static var previews: some View {
        ActivityHistoryView(activityDataManager: activityDataManager)
    }
}
