//
//  StatisticsSummaryView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 08/06/2025.
//

import SwiftUI

struct StatisticsSummaryView: View {
    
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    
    let statisticsManager = StatisticsManager.shared
    
    enum NavigationTarget {
        case TSSStatisticsView
        case HRStatisticsView
        case ActivityStatisticsView
        case DistanceStatisticsView
    }
    
    var body: some View {
        ScrollView {
                        
            DayOfWeekStatisticBarView(propertyName: "activities",
                                      navigationCoordinator: navigationCoordinator,
                                      detailView: NavigationTarget.ActivityStatisticsView)
            
            DayOfWeekStatisticBarDonutView(propertyName: "TSS",
                                           navigationCoordinator: navigationCoordinator,
                                           detailView: NavigationTarget.TSSStatisticsView)
            
            DayOfWeekStatisticBarView(propertyName: "distanceMeters",
                                      navigationCoordinator: navigationCoordinator,
                                      detailView: NavigationTarget.DistanceStatisticsView)
            
            DayOfWeekStatisticBarDonutView(propertyName: "time",
                                           navigationCoordinator: navigationCoordinator,
                                           detailView: NavigationTarget.HRStatisticsView)
            
    
        }
        .navigationDestination(for: NavigationTarget.self) { pathValue in

            if pathValue == .ActivityStatisticsView {
                DetailStatisticBarView(propertyName: "activities")
            }
            if pathValue == .TSSStatisticsView {
                DetailStatisticBarDonutView(propertyName: "TSS")
            }
            if pathValue == .DistanceStatisticsView {
                DetailStatisticBarView(propertyName: "distanceMeters")
            }
            if pathValue == .HRStatisticsView {
                DetailStatisticBarDonutView(propertyName: "time")
            }

        }

    }
}

#Preview {
    let navigationCoordinator = NavigationCoordinator()
    
    StatisticsSummaryView(navigationCoordinator: navigationCoordinator)
}
