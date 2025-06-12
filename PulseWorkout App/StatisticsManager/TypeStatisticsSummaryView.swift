//
//  ActivityStatisticsSummaryView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 12/06/2025.
//

import SwiftUI


struct TypeStatisticsSummaryView: View {
    @ObservedObject var statistics: TypeStatistics
    var imageSystemName: String
    var titleText: String
    var foregroundColor: Color
    var detailView: StatisticsSummaryView.NavigationTarget
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        
        GroupBox(label:
                    VStack {
            HStack {
                Image(systemName: imageSystemName)
                    .font(.title2)
                    .frame(width: 40, height: 40)
                Text(titleText)
                Spacer()
                
                
                Button {
                    navigationCoordinator.goToView(targetView: detailView)
                } label: {
                    HStack{
                        Image(systemName: "calendar")
                        Image(systemName: "chevron.forward")
                    }
                 }

            }
            .foregroundColor(foregroundColor)

        }
        )
        {
            StackedBarView(stackedBarData: statistics.weekByDayAsStackedBarData(WeekId.thisWeek))
            
        }

    }

}

#Preview {
    let navigationCoordinator = NavigationCoordinator()
    
    TypeStatisticsSummaryView(statistics: TypeStatistics(),
                              imageSystemName: "figure.run",
                              titleText: "Activities",
                              foregroundColor: .blue,
                              detailView: StatisticsSummaryView.NavigationTarget.ActivityStatisticsView,
                              navigationCoordinator: navigationCoordinator)
}

