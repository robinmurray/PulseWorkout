//
//  SummaryStatsHeaderView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 15/08/2025.
//

import SwiftUI


struct SingleStatHeaderView: View {

    @ObservedObject var statisticsManager = StatisticsManager.shared
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    var title: String = "Activities"
    var propertyName: String = "activities"
    var foregroundColor: Color = activitiesColor
    var navigationTarget: StatisticsProgressHeaderView.NavigationTarget = StatisticsProgressHeaderView.NavigationTarget.ActivityStatisticsView
    
    var frameWidth: CGFloat
    
    var body: some View {

        if #available(iOS 26.0, *) {
            HStack {
                
                VStack {
                    

                        VStack {
                            Text(title)
                                .font(.caption)
                                .bold()
                            
                            Button {
                                navigationCoordinator.goToView(targetView: navigationTarget)
                            } label: {
                                BarView(stackedBarChartData: statisticsManager.weekBuckets.asWeekStackedBarChartData(propertyName: propertyName, filterList: ["last", "this"]))
                                
                            }
                        }
                        .glassEffect(.regular.tint(foregroundColor.opacity(0.1)), in: .rect(cornerRadius: 10)).tint(activitiesColor)

                }
                .frame(width: frameWidth, height: 100)
                
            }
        } else {
            // Fallback on earlier versions
            ZStack {
                
                RoundedRectangle(cornerRadius: 10)
                    .stroke(foregroundColor, lineWidth: 1)
                
                VStack {
                        Text(title)
                        .font(.caption)
                        .bold()
                    
                    Button {
                        navigationCoordinator.goToView(targetView: navigationTarget)
                    } label: {
                        
                        BarView(stackedBarChartData: statisticsManager.weekBuckets.asWeekStackedBarChartData(propertyName: propertyName, filterList: ["last", "this"]))

                    }
                    
                }
            }
            .frame(width: frameWidth)
        }
        

        
    }
}


struct SummaryStatsHeaderView: View {
    
    @ObservedObject var statisticsManager = StatisticsManager.shared
    @ObservedObject var navigationCoordinator: NavigationCoordinator

    
    var body: some View {
        
        GeometryReader { geometry in
            let padWidth: CGFloat = 1
            let frameWidth: CGFloat = max(((geometry.size.width - (8 * padWidth)) / 4 ) - 4, 10)
        
            HStack {


                SingleStatHeaderView(navigationCoordinator: navigationCoordinator,
                                     title: "Activities",
                                     propertyName: "activities",
                                     foregroundColor: activitiesColor,
                                     navigationTarget: StatisticsProgressHeaderView.NavigationTarget.ActivityStatisticsView,
                                     frameWidth: frameWidth)
                
                Spacer()
                
                SingleStatHeaderView(navigationCoordinator: navigationCoordinator,
                                     title: "Load",
                                     propertyName: "TSSByZone",
                                     foregroundColor: TSSColor,
                                     navigationTarget: StatisticsProgressHeaderView.NavigationTarget.TSSStatisticsView,
                                     frameWidth: frameWidth)

                Spacer()
                
                SingleStatHeaderView(navigationCoordinator: navigationCoordinator,
                                     title: "Distance",
                                     propertyName: "distanceMeters",
                                     foregroundColor: distanceColor,
                                     navigationTarget: StatisticsProgressHeaderView.NavigationTarget.DistanceStatisticsView,
                                     frameWidth: frameWidth)

                Spacer()
                
                SingleStatHeaderView(navigationCoordinator: navigationCoordinator,
                                     title: "Time",
                                     propertyName: "timeByZone",
                                     foregroundColor: timeByHRColor,
                                     navigationTarget: StatisticsProgressHeaderView.NavigationTarget.HRStatisticsView,
                                     frameWidth: frameWidth)

                Spacer()

            }
        }

    }

}

#Preview {
    let navigationCoordinator = NavigationCoordinator()
    SummaryStatsHeaderView(navigationCoordinator: navigationCoordinator)
}
