//
//  BTDetailDeviceView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 18/03/2023.
//

import SwiftUI

struct BTDetailDeviceView: View {
    
    var btDevice: BTDevice
    var bluetoothManager: BTDevicesController
    
    init(bluetoothManager: BTDevicesController) {
        self.bluetoothManager = bluetoothManager
        self.btDevice = bluetoothManager.activeDetailDevice!
        
    }

    func forgetDevice() {
        bluetoothManager.forgetDevice(device: btDevice)
        bluetoothManager.appState = .knownDevices
    }
    
    func dismiss() {
        bluetoothManager.appState = .knownDevices
    }

    var body: some View {
        
        Form {
                
            Section(header: Text("Device")) {
                HStack {
                    Text(btDevice.name)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    Spacer()
                    
                }

                HStack {
                    Text(btDevice.connectionState == .connected ? "Connected" : "Disconnected" )
                        .foregroundColor(Color.white)
                    Spacer()
                }
            }
            .foregroundStyle(.blue)

            Section(header: Text("Device Information")) {
                HStack {
                    List {
                        ForEach((btDevice.deviceInfo).sorted(by: >), id: \.key) { key, value in
                            BTDeviceInfoView(key: key, value: value)
                        }
                    }
                    .listStyle(.carousel)
                    
                    Spacer()
                }
            }
            .foregroundStyle(.blue)

            Section(header: Text("Services")) {
                HStack{
                    List(btDevice.serviceDescriptions(), id: \.self) { service in Text(service)
                            .foregroundColor(Color.white)
                            .dynamicTypeSize(.xSmall)
                            .fontWeight(.bold)
                    }
                    .listStyle(.carousel)
                    
                    Spacer()
                }
                
            }
            .foregroundStyle(.blue)

            Section() {
                HStack {
                    Text("Forget Device")
                        .foregroundColor(Color.yellow)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: forgetDevice) {
                        Image(systemName: "trash.circle")
                    }
                    .foregroundColor(Color.yellow)
                    .font(.title)
                    .frame(width: 40, height: 40)
                    .background(Color.clear)
                    .clipShape(Circle())
                    .buttonStyle(PlainButtonStyle())
                    
                }
                
                Button("Dismiss", action: { dismiss() })
                    .buttonStyle(.borderedProminent)
                    .tint(Color.gray)
            }
            
        }
    }
    
}

struct BTDetailDeviceView_Previews: PreviewProvider {
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    
    init() {
        BTDetailDeviceView_Previews.bluetoothManager.activeDetailDevice = BTDevice(id: UUID(uuidString: "B1D7C9D0-12AC-FABC-FC29-B00EDE23F68E")!, name: "TICKR C703", services: ["Service 1", "Service 2"], deviceInfo: [:])
    }
    static var previews: some View {
        BTDetailDeviceView(bluetoothManager: bluetoothManager)
    }
}
