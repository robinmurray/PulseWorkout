//
//  StatisticsView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 20/11/2024.
//

import SwiftUI
import HealthKit



struct StatisticsView: View {
    
    @ObservedObject var navigationCoordinator: NavigationCoordinator

    var body: some View {
        
        VStack {

            StatisticsProgressHeaderView(navigationCoordinator: navigationCoordinator)
            
            ScrollView {
                
                StatisticsSummaryView(navigationCoordinator: navigationCoordinator)

                Spacer()

            }
 
        }
 
        

    }
}

#Preview {

    let navigationCoordinator = NavigationCoordinator()
        
    StatisticsView(navigationCoordinator: navigationCoordinator)
}

