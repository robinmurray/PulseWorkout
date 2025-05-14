//
//  UserMetricsView.swift
//  PulseWorkout
//
//  Created by Robin Murray on 18/04/2025.
//

import SwiftUI


struct UserMetricsView: View {
    
    var body: some View {
        
        Form {

            NavigationLink(
                destination: CyclePowerZonesView(userPowerMetrics: SettingsManager.shared.userPowerMetrics)) {
                    HStack {
                        Label("Cycling Power Zones", systemImage: powerIcon)
                            .foregroundStyle(powerColor)

                        Spacer()
                    }
                }
            
            NavigationLink(
                destination: CyclePowerZonesView(userPowerMetrics: SettingsManager.shared.userPowerMetrics)) {
                    HStack {
                        Label("Heart Rate Zones", systemImage: heartRateIcon)
                            .foregroundStyle(heartRateColor)

                        Spacer()
                    }
                }
            
        }
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)

        
    }

}

#Preview {
    
    UserMetricsView()
    
}
