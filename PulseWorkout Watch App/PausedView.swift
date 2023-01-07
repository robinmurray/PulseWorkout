//
//  PausedView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 23/12/2022.
//

import SwiftUI

struct PausedView: View {

    @ObservedObject var profileData: ProfileData

    init(profileData: ProfileData) {
        self.profileData = profileData
    }


    var body: some View {
        VStack{
             Button(action: WKInterfaceDevice.current().enableWaterLock) {
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

                        Button(action: profileData.resumeWorkout) {
                            Image(systemName: "playpause.circle.fill")
                        }
                        .foregroundColor(Color.green)
                        .frame(width: 40, height: 40)
                        .font(.title)
                        .background(Color.clear)
                        .clipShape(Circle())
                        
                        Text("Resume")
                            .foregroundColor(Color.green)
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

        }

    }
    
}

struct PausedView_Previews: PreviewProvider {
    
    static var profileData = ProfileData()

    static var previews: some View {
        PausedView(profileData: profileData)
    }
}
