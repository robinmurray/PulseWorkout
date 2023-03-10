//
//  BTKnownDeviceView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 25/02/2023.
//

import SwiftUI

struct BTKnownDeviceView: View {
    var btDevice: BTDevice
    var btManager: BTDevicesController
    
    init(btDevice: BTDevice, btManager: BTDevicesController) {
        self.btDevice = btDevice
        self.btManager = btManager
        
    }
    
    func forgetDevice() {
        btManager.forgetDevice(device: btDevice)
    }
    
    var body: some View {
        VStack {
            BTDeviceView(btDevice: btDevice)
            HStack {
                Text(btDevice.connected(bluetoothManager: btManager) ? "Connected" : "")
//                Image(systemName: "link.circle.fill").foregroundColor(btDevice.connected(bluetoothManager: btManager) ? Color.blue : Color.gray)

                Spacer()
                VStack{
                    Button(action: forgetDevice) {
                                Image(systemName: "trash.circle")
                    }
                    .foregroundColor(Color.yellow)
                    .font(.title)
                    .frame(width: 40, height: 40)
                    .background(Color.clear)
                    .clipShape(Circle())
                    .buttonStyle(PlainButtonStyle())
                            
                    Text("Forget")
                    .foregroundColor(Color.yellow)
                    
                    Spacer()
                }
            }
        }
    }
}

struct BTKnownDeviceView_Previews: PreviewProvider {
    static var device = BTDevice(id: UUID(uuidString: "B1D7C9D0-12AC-FABC-FC29-B00EDE23F68E")!, name: "TICKR C703", services: ["Service 1", "Service 2"])
    static var workoutManager = WorkoutManager()
    static var btManager: BTDevicesController = BTDevicesController(workoutManager: workoutManager)
    
    static var previews: some View {
        BTKnownDeviceView(btDevice: device, btManager: btManager)
    }
}
