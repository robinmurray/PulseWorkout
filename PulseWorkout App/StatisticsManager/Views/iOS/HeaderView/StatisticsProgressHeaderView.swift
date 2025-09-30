//
//  StatisticsProgressHeaderView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 15/08/2025.
//

import SwiftUI
import Charts

struct StatisticsProgressHeaderView: View {
    
    var body: some View {
        
        VStack {
            
            //            Text("Week Statistics")
            Divider()
            TabView() {
                

                SummaryStatsHeaderView()

                Text("Tab 1")
                Text("Tab 2")
                Text("Tab 3")
            }
            .tabViewStyle(.page)
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .interactive))


        }
        .frame(height: 140)
        .padding()
        .background(.gray.opacity(0.25))
 
    }
}


#Preview {
    StatisticsProgressHeaderView()
}
