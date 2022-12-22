//
//  StopView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 22/12/2022.
//

import SwiftUI

struct StopView: View {

    @ObservedObject var profileData: ProfileData

    init(profileData: ProfileData) {
        self.profileData = profileData
    }

    var body: some View {
        VStack{
            Button(action: profileData.startStopHRMonitor) {
                Image(systemName: "stop.circle")
            }
            .foregroundColor(Color.red)
            .frame(width: 20, height: 30)
            .scaleEffect(2)
            .background(Color.clear)
            
            Text("Stop")
                .foregroundColor(Color.red)
        }

    }
    
}

struct StopView_Previews: PreviewProvider {
    
    static var profileData = ProfileData()

    static var previews: some View {
        StopView(profileData: profileData)
    }
}
