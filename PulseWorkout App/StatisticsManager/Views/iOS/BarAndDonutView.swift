//
//  BarAndDonutView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 23/09/2025.
//

import SwiftUI

struct BarAndDonutView: View {
    var stackedBarChartData: StackedBarChartData

    var body: some View {
        
        VStack {

            BarView(stackedBarChartData: stackedBarChartData)
            
            DonutView(stackedBarChartData: stackedBarChartData)

        }


    }
}

/*
#Preview {
    BarAndDonutView()
}
*/
