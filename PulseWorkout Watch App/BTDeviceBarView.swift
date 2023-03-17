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

    func getBatteryImage(batteryLevel: Int?) -> String{
        
        let level = batteryLevel ?? 100
        switch level {
        case 0:
            return "battery.0"
        case 1...25:
            return "battery.25"
        case 26...50:
            return "battery.50"
        case 51...75:
            return "battery.75"
        default:
            return "battery.100.bolt"
        }
    }
    
    func getBatteryColor(batteryLevel: Int?) -> Color {

        if batteryLevel == nil {
            return Color.gray
        }
        
        let level = batteryLevel ?? 100
        switch level {
        case 0:
            return Color.red
        case 1...25:
            return Color.red
        case 26...50:
            return Color.orange
        default:
            return Color.green
        }

    }
    
    var body: some View {
        HStack {
            Image(systemName:"heart.fill")
                .foregroundColor(BTconnectedColour[workoutManager.BTHRMConnected])
            Image(systemName:getBatteryImage(batteryLevel: workoutManager.BTHRMBatteryLevel))
                .foregroundColor(getBatteryColor(batteryLevel: workoutManager.BTHRMBatteryLevel))
            Image(systemName:"dumbbell")
                .foregroundColor(Color.gray)
            Image(systemName:getBatteryImage(batteryLevel: workoutManager.BTcyclePowerBatteryLevel))
                .foregroundColor(getBatteryColor(batteryLevel: workoutManager.BTcyclePowerBatteryLevel))
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
