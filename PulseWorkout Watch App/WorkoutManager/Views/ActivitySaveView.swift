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

    @State var activityRecord: ActivityRecord
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading) {
            ActivityHeaderView(activityRecord: activityRecord)
            Divider()
            Button(action: SaveActivity) {
                Text("Done").padding([.leading, .trailing], 40)

            }
            .buttonStyle(.borderedProminent)
            .tint(Color.blue)
            


        }
    }
    
    func SaveActivity() {
        activityDataManager.saveActivityRecord(activityRecord: workoutManager.activityRecord)
                
        dismiss()
    }

}

struct ActivitySaveView_Previews: PreviewProvider {
    static var record = ActivityRecord()
    static var workoutManager = WorkoutManager()
    static var activityDataManager = ActivityDataManager()

    static var previews: some View {
        ActivitySaveView(workoutManager: workoutManager,
                         activityDataManager: activityDataManager,
                         activityRecord: record)
    }
}
