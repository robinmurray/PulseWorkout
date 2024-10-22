//
//  BTContentView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 17/03/2023.
//

import SwiftUI


enum BTAppState {
    case knownDevices, discoverDevices, deviceDetails
}

struct BTContentView: View {

    @ObservedObject var bluetoothManager: BTDevicesController
    
    init(bluetoothManager: BTDevicesController) {
        self.bluetoothManager = bluetoothManager
    }

    var body: some View {
        
        BTStartDiscoverView(bluetoothManager:  bluetoothManager)
    }

}

struct BTContentView_Previews: PreviewProvider {
    static var bluetoothManager = BTDevicesController(requestedServices: nil)

    static var previews: some View {
        BTContentView(bluetoothManager: bluetoothManager)
    }
}
