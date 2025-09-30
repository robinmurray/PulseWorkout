//
//  DayOfWeekStatisticBarDonutView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 19/06/2025.
//

import SwiftUI

struct DayOfWeekStatisticBarDonutView: View {
    
    @ObservedObject var statisticsManager: StatisticsManager = StatisticsManager.shared
    var propertyName: String
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    var detailView: StatisticsSummaryView.NavigationTarget
    
    var body: some View {
        ScrollView {
            GroupBox(label:
                        VStack {
                HStack {
                    Image(systemName: PropertyViewParamaters[propertyName]?.imageSystemName ?? "exclamationmark.triangle")
                        .font(.title2)
                        .frame(width: 40, height: 40)
                    Text(PropertyViewParamaters[propertyName]?.titleText ?? "Error!")
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
                .foregroundColor(PropertyViewParamaters[propertyName]?.foregroundColor ?? .red)

            }
            )
            {
                VStack {

                    BarAndDonutView(
                        stackedBarChartData: statisticsManager.thisWeekDayBuckets.asDayOfWeekStackedBarChartData(propertyName: propertyName))
                }

                
            }
        }
        

    }
}


#Preview {
    DayOfWeekStatisticBarDonutView(propertyName: "TSS",
                                   navigationCoordinator: NavigationCoordinator(),
                                   detailView: StatisticsSummaryView.NavigationTarget.TSSStatisticsView)
}
