//
//  StatisticsProgressHeaderView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 15/08/2025.
//

import SwiftUI
import Charts

struct StatisticsProgressHeaderView: View {
   
    @ObservedObject var navigationCoordinator: NavigationCoordinator

    enum NavigationTarget {
        case TSSStatisticsView
        case HRStatisticsView
        case ActivityStatisticsView
        case DistanceStatisticsView
    }
    
    var body: some View {
        
        VStack {
            
            //            Text("Week Statistics")
            Divider()
            TabView() {
                

                SummaryStatsHeaderView(navigationCoordinator: navigationCoordinator)

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
        .navigationDestination(for: NavigationTarget.self) { pathValue in

            if pathValue == .ActivityStatisticsView {
                DetailStatisticBarDonutView(propertyName: "activities")
            }
            if pathValue == .TSSStatisticsView {
                DetailStatisticBarDonutView(propertyName: "TSS")
            }
            if pathValue == .DistanceStatisticsView {
                DetailStatisticBarDonutView(propertyName: "distanceMeters")
            }
            if pathValue == .HRStatisticsView {
                DetailStatisticBarDonutView(propertyName: "time")
            }

        }
 
    }
}


#Preview {
    
    let navigationCoordinator = NavigationCoordinator()
    StatisticsProgressHeaderView(navigationCoordinator: navigationCoordinator)
}
