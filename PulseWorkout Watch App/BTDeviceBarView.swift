//
//  BTDevicesView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 15/02/2023.
//

import SwiftUI

let BTconnectedColour: [Bool: Color] =
[false: Color.gray,
 true: Color.blue]



struct BTDeviceBarView: View {
    
    @ObservedObject var workoutManager: WorkoutManager

    let screenWidth = WKInterfaceDevice.current().screenBounds.width
    
    init(workoutManager: WorkoutManager) {
        self.workoutManager = workoutManager
    }

    var body: some View {
        HStack {
            Image(systemName:"heart.fill")
                .foregroundColor(BTconnectedColour[workoutManager.BTHRMConnected])
            Image(systemName:"battery.100.bolt")
                .foregroundColor(Color.gray)
            Image(systemName:"dumbbell")
                .foregroundColor(Color.gray)
            Image(systemName:"battery.100.bolt")
                .foregroundColor(Color.gray)
            Image(systemName:"speedometer")
                .foregroundColor(Color.gray)
            Image(systemName:"battery.100.bolt")
                .foregroundColor(Color.gray)

            Spacer().frame(maxWidth: .infinity)
        }.imageScale(screenWidth > 190 ? .medium: .small)
    }
}

struct BTDevicesView_Previews: PreviewProvider {

    static var workoutManager = WorkoutManager()

    static var previews: some View {
        BTDeviceBarView(workoutManager: workoutManager)
    }
}
