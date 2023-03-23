//
//  BTDeviceInfoView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 19/03/2023.
//

import SwiftUI

struct BTDeviceInfoView: View {

    var key: String
    var value: String
    
    init(key: String, value: String) {
        self.key = key
        self.value = value
        
    }

    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text(key)
                        .foregroundColor(Color.white)
                        .dynamicTypeSize(.xSmall)
                        .fontWeight(.bold)
                    Spacer()
                }
                HStack {
                    Text(value)
                        .foregroundColor(Color.blue)
                        .dynamicTypeSize(.xSmall)
                    Spacer()
                }
            }
        }
    }
}

struct BTDeviceInfoView_Previews: PreviewProvider {
    
    static var key: String = "Key 1"
    static var value: String = "Value 1"

    static var previews: some View {
        BTDeviceInfoView(key: key, value: value)
    }
}
