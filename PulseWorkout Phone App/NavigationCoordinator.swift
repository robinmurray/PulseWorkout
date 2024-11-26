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




class NavigationCoordinator: ObservableObject {
    @Published var selectedTab: ContentViewTab = .home
    @Published var newActivityPath: NavigationPath = NavigationPath()
    @Published var homePath: NavigationPath = NavigationPath()
    @Published var statsPath: NavigationPath = NavigationPath()
    @Published var settingsPath: NavigationPath = NavigationPath()

    var selectedProfile: ActivityProfile?
    var selectedActivityRecord: ActivityRecord?
    
    /*
    var paths: [ContentViewTab: NavigationPath]
    
    init() {
        paths = [.home: homePath,
                 .newActivity: newActivityPath,
                 .stats: statsPath,
                 .settings: settingsPath]
    }
*/
    
    
    func goToTab( tab: ContentViewTab) {
        selectedTab = tab
    }

    func goToView( targetView: any Hashable) {
        switch selectedTab {
        case .home:
            homePath.append(targetView)
            
        case .newActivity:
            newActivityPath.append(targetView)
            
        case .stats:
            statsPath.append(targetView)
            
        case .settings:
            settingsPath.append(targetView)
            
        }
    }

    /// Go to home tab and pop it to root. Before doing so pop current screen to root...
    func home() {
        
        if selectedTab != .home {
            popToRoot()
        }
        selectedTab = .home
        popToRoot()

    }

    func back() {
        switch selectedTab {
        case .home:
            if homePath.count > 0 {
                homePath.removeLast()
            }

        case .newActivity:
            if newActivityPath.count > 0 {
                newActivityPath.removeLast()
            }

        case .stats:
            if statsPath.count > 0 {
                statsPath.removeLast()
            }

        case .settings:
            if settingsPath.count > 0 {
                settingsPath.removeLast()
            }

        }

    }

    func popToRoot() {
        switch selectedTab {
        case .home:
            while homePath.count > 0 { back() }

        case .newActivity:
            while newActivityPath.count > 0 { back() }

        case .stats:
            while statsPath.count > 0 { back() }

        case .settings:
            while settingsPath.count > 0 { back() }

        }

    }

    
}
