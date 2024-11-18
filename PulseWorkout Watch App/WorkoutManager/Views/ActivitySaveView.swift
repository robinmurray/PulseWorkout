//
//  ActivitySaveView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 24/08/2023.
//

import SwiftUI




struct ActivitySaveView: View {
   
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var dataCache: DataCache
    @Environment(\.dismiss) private var dismiss

/*    init(liveActivityManager: LiveActivityManager) {
        self.liveActivityManager = liveActivityManager
    }
  */
    
    var body: some View {
        VStack(alignment: .leading) {
 /*           ScrollView {
                ActivityDetailView(activityRecord: liveActivityManager.liveActivityRecord ??
                                   ActivityRecord(settingsManager: liveActivityManager.settingsManager))
 //           }
*/
            ActivityHeaderView(activityRecord: liveActivityManager.liveActivityRecord ??
                               ActivityRecord(settingsManager: liveActivityManager.settingsManager))
            Divider()
            
            NavigationStack {
                NavigationLink("Summary",
                               destination: ActivityDetailView(activityRecord: liveActivityManager.liveActivityRecord ??
                                                               ActivityRecord(settingsManager: liveActivityManager.settingsManager),
                                                              dataCache: dataCache))
            }
            
            Button(action: SaveActivity) {
                Text("Done").padding([.leading, .trailing], 40)

            }
            .buttonStyle(.borderedProminent)
            .tint(Color.blue)
            


        }
        .navigationBarBackButtonHidden(true)
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
    static var dataCache = DataCache(settingsManager: settingsManager)
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                         bluetoothManager: bluetoothManager,
                                                         settingsManager: settingsManager,
                                                         dataCache: dataCache)
    

    static var previews: some View {
        ActivitySaveView(liveActivityManager: liveActivityManager,
                         dataCache: dataCache)
    }
}
