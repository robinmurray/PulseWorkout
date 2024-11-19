//
//  ActivityHistoryHeaderView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 16/11/2024.
//

import SwiftUI

struct ActivityHistoryHeaderView: View {
    var body: some View {
        VStack {

            HStack{
                VStack {
                    HStack {
                        Text("This week").bold().foregroundStyle(.blue)
                        Spacer()
                    }
                    
                    HStack {
                        Text("7 Activities")
                        Spacer()
                    }
                    HStack {
                        Text("350 km")
                        Spacer()
                    }
                    HStack {
                        Text("800 TS")
                        Spacer()
                    }
                    
                }
                
                Spacer()
                VStack {
                    HStack {
                        Text("Previous 7 days").bold().foregroundStyle(.blue)
                        Spacer()
                    }
                    
                    HStack {
                        Text("5 Activities")
                        Spacer()
                    }
                    HStack {
                        Text("150 km")
                        Spacer()
                    }
                    HStack {
                        Text("600 TS")
                        Spacer()
                    }
                    
                }

            }
            
        }
    }
}

#Preview {
    ActivityHistoryHeaderView()
}
