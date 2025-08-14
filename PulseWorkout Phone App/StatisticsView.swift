//
//  StatisticsView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 20/11/2024.
//

import SwiftUI
import HealthKit

struct DestinationView: View {
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    var type: String

    
    var body: some View {
        VStack {
            Text(type).font(.title)

//            Text("\(navigationPath)")
            Button("Back to root") {
                // to navigate to root view you simply pop all the views from navPath
                navigationCoordinator.statsPath.removeLast()
            }
            
            Button("Go!") {
  //              navigationCoordinator.goToTab(tab: .home)
                navigationCoordinator.statsPath.append(DestinationViewNavOptions.DestinationView)
            }
            .buttonStyle(.bordered)
        }
        .navigationDestination(for: DestinationViewNavOptions.self) { pathValue in

            if pathValue == DestinationViewNavOptions.DestinationView {

                DestinationView(navigationCoordinator: navigationCoordinator, type: "Hello World Again")
            }
            
        }

    }
    
}

enum DestinationViewNavOptions {
    case DestinationView
}
enum MyViews {
    case DestinationView
}
struct StatisticsView: View {
    
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @ObservedObject var profileManager: ProfileManager
    @ObservedObject var liveActivityManager: LiveActivityManager
    @ObservedObject var dataCache: DataCache
    
    var body: some View {
        
        VStack {

            ActivityHistoryHeaderView()
            
            ScrollView {

//                Spacer()
                
                StatisticsSummaryView(navigationCoordinator: navigationCoordinator)
                Spacer()
                Button("Migrate...") {
                    print("Perform migration")
                    let migrationManager = MigrationManager()
                    migrationManager.fetchAllRecordsToUpdate()
                }

                Spacer()
                
                Button("Fetch All...") {
                    print("Fetching All Records")

                    CKProcessAllActivityRecords(recordProcessFunction: testProcessAllActivityRecords,
                    completionFunction: { }).execute()
                }

                Spacer()

                Button("Test Strava Fetch...") {
                    print("Fetch from Strava")
    //                let stravaManager = StravaManager()
    //                stravaManager.fetchActivities(perPage: 5,
    //                                              completionHandler: stravaManager.dummyFetchCompletion)

                    StravaFetchActivities(completionHandler: StravaFetchActivities.dummyCompletion).execute()
                }
                Button("Fetch - force reauth...") {

                    StravaFetchActivities(completionHandler: StravaFetchActivities.dummyCompletion,
                                          forceReauth: true).execute()
                }
                Button("Fetch - force refresh...") {

                    StravaFetchActivities(completionHandler: StravaFetchActivities.dummyCompletion,
                                          forceRefresh: true).execute()
                }
                Button("Test Strava Fetch and save 5 days...") {
                    print("Fetch from Strava and save")
                    
                    StravaFetchLatestActivities(after: Date.now.addingTimeInterval(-86400 * 5),
                                                completionHandler: { dataCache.refreshUI()}).execute()
                    /*
                    StravaFetchActivities(completionHandler: {fetchedActivities in
                        
                        for (index, activity) in fetchedActivities.enumerated() {
                            if index < 1 {
                                StravaFetchFullActivity(stravaActivityId: activity.id!,
                                                        completionHandler: {activityRecord in
                                    
                                    activityRecord.save(dataCache: self.dataCache)
                                }
                                ).execute()
                            }
                        }
                    }
                    ).execute()
                    */
                }
                
                Spacer()
                SwipeButton(swipeText: "Swipe to go Home",
                            perform : {navigationCoordinator.goToTab(tab: .home)},
                            buttonColor: Color.yellow)

                Spacer()
                Text("Statistics!")
                Spacer()
                Button("Go!") {
                    navigationCoordinator.goToTab(tab: .home)
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .navigationDestination(for: MyViews.self) { pathValue in

                if pathValue == MyViews.DestinationView {

                    DestinationView(navigationCoordinator: navigationCoordinator, type: "Hello World")
                }
            }
        }
        

    }
}

#Preview {

    let navigationCoordinator = NavigationCoordinator()
    let locationManager = LocationManager()
    let dataCache = DataCache()
    let bluetoothManager = BTDevicesController(requestedServices: nil)
    let liveActivityManager = LiveActivityManager(locationManager: locationManager,
                                                  bluetoothManager: bluetoothManager,
                                                  dataCache: dataCache)
    let profileManager = ProfileManager()
    
    
    StatisticsView(navigationCoordinator: navigationCoordinator,
                   profileManager: profileManager,
                   liveActivityManager: liveActivityManager,
                   dataCache: dataCache)
}

