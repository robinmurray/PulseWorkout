//
//  ActivitySaveView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 24/08/2023.
//

import SwiftUI

struct ActivitySaveView: View {
   
    @ObservedObject var workoutManager: WorkoutManager
    @ObservedObject var activityDataManager: ActivityDataManager

//    @State var activityRecord: ActivityRecord
    
    @Environment(\.dismiss) private var dismiss

    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
        self.activityDataManager = workoutManager.activityDataManager
    }
    
    
    var body: some View {
        VStack(alignment: .leading) {
            ActivityHeaderView(activityRecord: self.activityDataManager.liveActivityRecord ??
                               self.activityDataManager.dummyActivityRecord)
            Divider()
            Button(action: SaveActivity) {
                Text("Done").padding([.leading, .trailing], 40)

            }
            .buttonStyle(.borderedProminent)
            .tint(Color.blue)
            


        }
    }
    
    func SaveActivity() {
        activityDataManager.saveActivityRecord()
                
        dismiss()
    }

}

struct ActivitySaveView_Previews: PreviewProvider {
    static var settingsManager = SettingsManager()
    static var record = ActivityRecord(settingsManager: settingsManager)
    static var activityDataManager = ActivityDataManager(settingsManager: settingsManager)

    static var locationManager = LocationManager(activityDataManager: activityDataManager, settingsManager: settingsManager)

    static var workoutManager = WorkoutManager(locationManager: locationManager, activityDataManager: activityDataManager,
        settingsManager: settingsManager)
    

    static var previews: some View {
        ActivitySaveView(workoutManager: workoutManager)
    }
}
