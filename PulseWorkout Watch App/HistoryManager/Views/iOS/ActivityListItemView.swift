//
//  ActivityListItemView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 15/11/2024.
//


import SwiftUI

struct ActivityListItemView: View {
    
    @ObservedObject var activityRecord: ActivityRecord
    var dataCache: DataCache
    
    func stravaColour(stravaSaveStatus: Int) -> Color {
        switch stravaSaveStatus {
        case StravaSaveStatus.saved.rawValue:
            return Color.green
        case StravaSaveStatus.toSave.rawValue:
            return Color.orange
        default:
            return Color.clear
        }
    }
    
    var body: some View {
        VStack {

            HStack {
                Text(activityRecord.name)
                    .foregroundStyle(.yellow)
                Spacer()
                VStack {
                    if activityRecord.toSavePublished {
                        Image(systemName: "icloud.slash.fill").foregroundColor(.red)
                    }
                    Image(systemName: "paperplane.circle").foregroundColor(
                        stravaColour(stravaSaveStatus: activityRecord.stravaSaveStatus))

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

            #if os(iOS)
            HStack {
                Image(uiImage: activityRecord.mapSnapshotImage ?? UIImage(systemName: "map")!.withTintColor(.blue))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, height: 150, alignment: .topLeading)
                Spacer()
            }

            #endif
        }
        #if os(iOS)
        /* FIX! Remove comment out once complete! */
        .onAppear( perform: { activityRecord.getMapSnapshot(datacache: dataCache) })
        #endif
        
    }

}


struct ActivityListItemView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var dataCache = DataCache(settingsManager: settingsManager)
    static var activityRecord = ActivityRecord(settingsManager: settingsManager)
    
    static var previews: some View {
        ActivityListItemView(activityRecord: activityRecord,
                             dataCache: dataCache)
    }
}

