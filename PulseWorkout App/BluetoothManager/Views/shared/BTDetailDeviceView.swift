//
//  BTDetailDeviceView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 18/03/2023.
//

import SwiftUI

struct BTDetailDeviceView: View {
    
    var btDevice: BTDevice
    @ObservedObject var bluetoothManager: BTDevicesController
    @Environment(\.presentationMode) var presentation

    init(bluetoothManager: BTDevicesController, btDevice: BTDevice) {
        self.bluetoothManager = bluetoothManager
        self.btDevice = btDevice
        
    }

    func forgetDevice() {
        bluetoothManager.forgetDevice(device: btDevice)
        self.presentation.wrappedValue.dismiss()
    }
    
    var body: some View {
        
        Form {
                
            Section(header: Text("Sensor")) {
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
            #if os(watchOS)
            .navigationTitle{
                Label(btDevice.name, systemImage: "badge.plus.radiowaves.right")
                    .foregroundColor(.blue)
            }
            #endif
            
            Section(header: Text("Sensor Information")) {
                HStack {
                    List {
                        ForEach((btDevice.deviceInfo).sorted(by: >), id: \.key) { key, value in
                            BTDeviceInfoView(key: key, value: value)
                        }
                    }
                    #if os(watchOS)
                    .listStyle(.carousel)
                    #endif
                    
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
                    #if os(watchOS)
                    .listStyle(.carousel)
                    #endif
                    
                    Spacer()
                }
                
            }
            .foregroundStyle(.blue)

            Section() {
                HStack {
                    Text("Forget Sensor")
                        .foregroundColor(Color.yellow)
                    
                    Spacer()
                    
                    Button(action: forgetDevice) {
                        Image(systemName: "trash.circle")
                    }
                    .foregroundColor(Color.yellow)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                    .background(Color.clear)
                    .clipShape(Circle())
                    .buttonStyle(PlainButtonStyle())
                    
                }
                
            }
            
        }
    }
    
}

struct BTDetailDeviceView_Previews: PreviewProvider {
    static var bluetoothManager = BTDevicesController(requestedServices: nil)
    static var btDevice = BTDevice(id: UUID(uuidString: "B1D7C9D0-12AC-FABC-FC29-B00EDE23F68E")!, name: "TICKR C703", services: ["Service 1", "Service 2"], deviceInfo: [:])
    

    static var previews: some View {
        BTDetailDeviceView(bluetoothManager: bluetoothManager, btDevice: btDevice)
    }
}
