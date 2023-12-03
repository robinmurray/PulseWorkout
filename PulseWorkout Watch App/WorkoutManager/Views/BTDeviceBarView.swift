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
    
    @ObservedObject var liveActivityManager: LiveActivityManager

    let screenWidth = WKInterfaceDevice.current().screenBounds.width
    
    init(liveActivityManager: LiveActivityManager) {
        self.liveActivityManager = liveActivityManager
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
        case 0...10:
            return Color.red
        case 11...15:
            return Color.yellow
        default:
            return Color.green
        }

    }
    
    var body: some View {
        HStack {
            Image(systemName:"heart.fill")
                .foregroundColor(BTconnectedColour[liveActivityManager.BTHRMConnected])
            Image(systemName:getBatteryImage(batteryLevel: liveActivityManager.BTHRMBatteryLevel))
                .foregroundColor(getBatteryColor(batteryLevel: liveActivityManager.BTHRMBatteryLevel))
            Image(systemName:"bolt")
                .foregroundColor(BTconnectedColour[liveActivityManager.BTcyclePowerConnected])
            Image(systemName:getBatteryImage(batteryLevel: liveActivityManager.BTcyclePowerBatteryLevel))
                .foregroundColor(getBatteryColor(batteryLevel: liveActivityManager.BTcyclePowerBatteryLevel))
            Image(systemName:"arrow.clockwise.circle")
                .foregroundColor(Color.gray)
            Image(systemName:"battery.100.bolt")
                .foregroundColor(Color.gray)

            Spacer().frame(maxWidth: .infinity)
        }.imageScale(screenWidth > 190 ? .medium: .small)
    }
}

struct BTDevicesView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var locationManager = LocationManager(settingsManager: settingsManager)
    static var dataCache = DataCache()
    static var liveActivityManager = LiveActivityManager(locationManager: locationManager, settingsManager: settingsManager,
        dataCache: dataCache)
    
    static var previews: some View {
        BTDeviceBarView(liveActivityManager: liveActivityManager)
    }
}
