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
             Button(action: lockScreen) {
                Image(systemName: "drop.circle")
            }
            .foregroundColor(Color.blue)
            .frame(width: 40, height: 40)
            .font(.title)
            .background(Color.clear)
            .clipShape(Circle())
            
            Text("Lock")
                .foregroundColor(Color.blue)

            HStack{

                Spacer()

                VStack{

                    Button(action: profileData.pauseWorkout) {
                            Image(systemName: "pause.circle")
                        }
                        .foregroundColor(Color.yellow)
                        .frame(width: 40, height: 40)
                        .font(.title)
                        .background(Color.clear)
                        .clipShape(Circle())
                        
                        Text("Pause")
                            .foregroundColor(Color.yellow)
                    }

                Spacer()

                VStack{
                    Button(action: profileData.endWorkout) {
                        Image(systemName: "stop.circle")
                    }
                    .foregroundColor(Color.red)
                    .frame(width: 40, height: 40)
                    .font(.title)
                    .background(Color.clear)
                    .clipShape(Circle())
                    
                    Text("Stop")
                        .foregroundColor(Color.red)
                    
                }

                Spacer()
            }
            .navigationTitle("Workout Control")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    func lockScreen() {
        WKInterfaceDevice.current().enableWaterLock()
        profileData.liveTabSelection = LiveScreenTab.liveMetrics
    }
}

struct StopView_Previews: PreviewProvider {
    
    static var profileData = ProfileData()

    static var previews: some View {
        StopView(profileData: profileData)
    }
}
