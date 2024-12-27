//
//  ActivityListItemExtensionView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 15/11/2024.
//

import SwiftUI

struct ActivityListItemExtensionView: View {
    @ObservedObject var activityRecord: ActivityRecord
    var dataCache: DataCache
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    HStack{
                        Text("Distance").foregroundStyle(.orange)
                        Spacer()
                    }
                    HStack {
                        Text(distanceFormatter(distance: activityRecord.distanceMeters))
                        Spacer()
                    }
                    
                }
                Spacer()
                VStack {
                    HStack {
                        Text("Ascent").foregroundStyle(.orange)
                        Spacer()
                    }
                    HStack {
                        Text(distanceFormatter(distance: activityRecord.totalAscent ?? 0, forceMeters: true))
                        Spacer()
                    }
                    
                }
                Spacer()
                VStack {
                    HStack {
                        Text("Time").foregroundStyle(.orange)
                        Spacer()
                    }
                    HStack {
                        Text(durationFormatter(elapsedSeconds: activityRecord.movingTime))
                        Spacer()
                    }
                    
                }
            }


            HStack {
                Image(uiImage: activityRecord.mapSnapshotImage ?? UIImage(systemName: "map")!.withTintColor(.blue))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 360, height: 180, alignment: .topLeading)
                Spacer()
            }

        }
        .onAppear( perform: { activityRecord.getMapSnapshot(dataCache: dataCache) })

        
    }

}

#Preview {
    let settingsManager = SettingsManager()
    let dataCache = DataCache(settingsManager: settingsManager)
    let activityRecord = ActivityRecord(settingsManager: settingsManager)
    
    ActivityListItemExtensionView(activityRecord: activityRecord, dataCache: dataCache)
}
