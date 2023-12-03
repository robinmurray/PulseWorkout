//
//  ActivitySaveView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 24/08/2023.
//

import SwiftUI

struct ActivitySaveView: View {
   
    @ObservedObject var liveActivityManager: LiveActivityManager
    @Environment(\.dismiss) private var dismiss

    init(liveActivityManager: LiveActivityManager) {
        self.liveActivityManager = liveActivityManager
    }
    
    
    var body: some View {
        VStack(alignment: .leading) {
            ActivityHeaderView(activityRecord: liveActivityManager.liveActivityRecord ??
                               ActivityRecord(settingsManager: liveActivityManager.settingsManager))
            Divider()
            Button(action: SaveActivity) {
                Text("Done").padding([.leading, .trailing], 40)

            }
            .buttonStyle(.borderedProminent)
            .tint(Color.blue)
            


        }
    }
    
    func SaveActivity() {
        liveActivityManager.saveLiveActivityRecord()
        dismiss()
    }

}

struct ActivitySaveView_Previews: PreviewProvider {
    static var settingsManager = SettingsManager()
    static var record = ActivityRecord(settingsManager: settingsManager)

    static var locationManager = LocationManager(settingsManager: settingsManager)
    
    static var dataCache = DataCache()

    static var liveActivityManager = LiveActivityManager(locationManager: locationManager, settingsManager: settingsManager,
        dataCache: dataCache)
    

    static var previews: some View {
        ActivitySaveView(liveActivityManager: liveActivityManager)
    }
}
