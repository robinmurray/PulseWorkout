//
//  SectionHeaderView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 15/12/2025.
//

import SwiftUI

struct SectionHeaderView: View {
    
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    var iconName: String = powerIcon
    var sectionTitle: String = "Power"
    var foregroundColor: Color = powerColor
    var navigationTarget: ActivityDetailView.NavigationTarget? = ActivityDetailView.NavigationTarget.ChartViewPower
    
    
    var body: some View {

        VStack {
        HStack {
            Image(systemName: iconName)
                    .font(.title2)
                    .frame(width: 40, height: 40)
            Text(sectionTitle)
            
            Spacer()
            
            if let navTarget = navigationTarget {
                if #available(iOS 26.0, *) {
                    Button(action: {
                        navigationCoordinator.goToView(targetView: navTarget)
                    })
                    {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .foregroundStyle(foregroundColor)
                    }
                    .buttonStyle(.glass)
                    .glassEffect(.clear)
                    .padding(.trailing, 10)
                } else {
                    Button(action: {
                        navigationCoordinator.goToView(targetView: navTarget)
                    })
                    {
                        Image(systemName: "chart.xyaxis.line")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .foregroundStyle(foregroundColor)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }


            
            
        }
        
        Divider()
            
        }
        .foregroundColor(foregroundColor)
        
    }
}

#Preview {
    SectionHeaderView(navigationCoordinator: NavigationCoordinator())
}
