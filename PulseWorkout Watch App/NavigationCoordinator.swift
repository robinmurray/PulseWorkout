//
//  NavigationCoordinator.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 23/11/2024.
//

import Foundation
import SwiftUI


enum ContentViewTab {
    case home, newActivity, stats, settings
}
enum TargetView {
    case LiveMetricsView
    case ProfileDetailView
    case NewProfileDetailView
}


class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: ContentViewTab = .home
    @Published var path: NavigationPath = NavigationPath()

    var selectedProfile: ActivityProfile?
    var selectedActivityRecord: ActivityRecord?
    
    func goToTab( tab: ContentViewTab) {
        selectedTab = tab
    }

    func goToView(targetView: any Hashable) {

        path.append(targetView)
        
    }

    func home() {
        
        popToRoot()
        selectedTab = .home
        
    }

    func back() {
        
        if path.count > 0 {
            path.removeLast()
        }
        
    }

    func popToRoot() {
        
        while path.count > 0 { back() }

    }

    
}
