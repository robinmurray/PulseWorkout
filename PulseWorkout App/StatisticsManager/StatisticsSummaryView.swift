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
                        
            TypeStatisticsSummaryView(statistics: statisticsManager.activityStatistics,
                                      imageSystemName: "figure.run",
                                      titleText: "Activities",
                                      foregroundColor: activitiesColor,
                                      detailView: NavigationTarget.ActivityStatisticsView,
                                      navigationCoordinator: navigationCoordinator)
            
            ZoneStatisticsSummaryView(statistics: statisticsManager.tssStatistics,
                                      imageSystemName: "figure.strengthtraining.traditional.circle",
                                      titleText: "Training Load",
                                      totalText: "Total Load",
                                      foregroundColor: TSSColor,
                                      detailView: NavigationTarget.TSSStatisticsView,
                                      navigationCoordinator: navigationCoordinator)
            
            TypeStatisticsSummaryView(statistics: statisticsManager.distanceStatistics,
                                      imageSystemName: distanceIcon,
                                      titleText: "Distance",
                                      foregroundColor: distanceColor,
                                      detailView: NavigationTarget.DistanceStatisticsView,
                                      navigationCoordinator: navigationCoordinator)
            
            ZoneStatisticsSummaryView(statistics: statisticsManager.hrStatistics,
                                      imageSystemName: "stopwatch",
                                      titleText: "Activity Time - by Heart Rate Zone",
                                      totalText: "Total Time",
                                      foregroundColor: timeByHRColor,
                                      detailView: NavigationTarget.HRStatisticsView,
                                      navigationCoordinator: navigationCoordinator)
            
            
        }
        .navigationDestination(for: NavigationTarget.self) { pathValue in

            if pathValue == .ActivityStatisticsView {
                TypeStatisticsDetailView(statistics: statisticsManager.activityStatistics,
                                         navigationTitle: "Activities",
                                         foregroundColor: activitiesColor)
            }
            if pathValue == .TSSStatisticsView {
                ZoneStatisticsDetailView(statistics: statisticsManager.tssStatistics,
                                   totalLabel: "Total Load",
                                   navigationTitle: "Training Load",
                                   foregroundColor: TSSColor)
            }
            if pathValue == .DistanceStatisticsView {
                TypeStatisticsDetailView(statistics: statisticsManager.distanceStatistics,
                                         navigationTitle: "Distance",
                                         foregroundColor: distanceColor)
            }
            if pathValue == .HRStatisticsView {
                ZoneStatisticsDetailView(statistics: statisticsManager.hrStatistics,
                                   totalLabel: "Total Time",
                                   navigationTitle: "Activity Time by Zone",
                                   foregroundColor: timeByHRColor)
            }

        }

    }
}

#Preview {
    let navigationCoordinator = NavigationCoordinator()
    
    StatisticsSummaryView(navigationCoordinator: navigationCoordinator)
}
