//
//  AltitudeChartImage.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 17/02/2025.
//

import SwiftUI
import Charts
import CloudKit

struct AltitudeData: Identifiable {
    let id = UUID()
    let distance: Double
    let altitude: Double
}


/// View used for creation of altitude image
struct AltitudeChartImage: View {
    
    var altitudeArray: [AltitudeData]
    
    var body: some View {
        Chart(altitudeArray)
        { chartPoint in

            AreaMark(
                x: .value("Distance", chartPoint.distance),
                y: .value("Altitude", chartPoint.altitude),
               stacking: .unstacked
                
            )
            .foregroundStyle(Gradient(colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.1)]))
            
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .background(Color.gray.opacity(0))
        .frame(width: 300, height: 150)

    }
}

#Preview {
    AltitudeChartImage(
        altitudeArray: [AltitudeData(distance: 0, altitude: 100),
                        AltitudeData(distance: 1, altitude: 200),
                        AltitudeData(distance: 2, altitude: 250),
                        AltitudeData(distance: 3, altitude: 400),
                        AltitudeData(distance: 4, altitude: 150),
                        AltitudeData(distance: 6, altitude: 260)])
}
