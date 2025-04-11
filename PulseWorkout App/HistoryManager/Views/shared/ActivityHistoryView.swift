//
//  ActivityHistoryView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 30/06/2023.
//

import SwiftUI


struct ActivityHistoryView: View {
    
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @ObservedObject var dataCache: DataCache
    @StateObject var refreshProgress: AsyncProgress = AsyncProgress()
    @State var fetching: Bool = false
    @State var fetchComplete: Bool = false

    enum NavigationTarget {
        case ActivityDetailView
        case MapRouteView
    }
    
    init(navigationCoordinator: NavigationCoordinator, dataCache: DataCache) {
        self.navigationCoordinator = navigationCoordinator
        self.dataCache = dataCache
    }
    
    var body: some View {
#if os(iOS)
        ActivityHistoryHeaderView()
#endif
        
        List {
            
            if refreshProgress.displayProgressView {
                AsyncProgressView(asyncProgress: refreshProgress)
            }
            
            ForEach(dataCache.UIRecordSet) {activityRecord in
                VStack {
                    Button(action: {
                        navigationCoordinator.selectedActivityRecord = activityRecord
                        navigationCoordinator.goToView(targetView: NavigationTarget.ActivityDetailView)
                    })
                    {
                        ActivityListItemView(activityRecord: activityRecord,
                                             dataCache: dataCache)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .swipeActions {
                        Button(role:.destructive) {
                            dataCache.delete(recordID:
                                activityRecord.recordID)
                        } label: {
                            Label("Delete", systemImage: "xmark.bin")
                        }
                            
                    }

                    #if os(iOS)
                    Button(action: {
                        navigationCoordinator.selectedActivityRecord = activityRecord
                        navigationCoordinator.goToView(targetView: NavigationTarget.MapRouteView)
                    })
                    {
                        ActivityListItemExtensionView(activityRecord: activityRecord, dataCache: dataCache)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    
                    #endif
                }

            }
            if fetching {
                ProgressView()
            }
            
            if !fetching && !fetchComplete {
              ProgressView()
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    fetching = true
                    let latestUIDate = dataCache.getLatestUIDate()

                    CKActivityQueryOperation(startDate: latestUIDate,
                                             blockCompletionFunction: {records in
                        dataCache.addRecordsToUI(records: records)
                        fetching = false
                        fetchComplete = dataCache.isFetchComplete(records: records)},
                                             resultsLimit: dataCache.cacheSize,
                                             qualityOfService: .userInitiated).execute()
                }
            }
        }
        #if os (iOS)
        .listStyle(.grouped)
        #endif
        .navigationDestination(for: NavigationTarget.self) { pathValue in

            if pathValue == .ActivityDetailView {

                ActivityDetailView(navigationCoordinator: navigationCoordinator,
                                   activityRecord: navigationCoordinator.selectedActivityRecord!,
                                   dataCache: dataCache)
            }
            else if pathValue == .MapRouteView {
                
                MapRouteView(activityRecord: navigationCoordinator.selectedActivityRecord!,
                             dataCache: dataCache)
            }
            
        }
    #if os(watchOS)
        .navigationTitle {

            HStack {
/*                Image(systemName: "book.circle")
                    .foregroundColor(Color.black)
                    .background(Color.yellow)
                    .clipShape(Circle())
                Text("History")
                    .foregroundColor(Color.yellow)
                */
                Button(action: {
                    dataCache.refreshUI(qualityOfService: .userInitiated)
                })
                {
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    
                }
                .foregroundColor(Color.yellow)
            }
        }
    #endif
        .refreshable {

#if os(watchOS)
            dataCache.refreshUI()
            fetchComplete = false
#endif
#if os(iOS)
            if SettingsManager.shared.fetchFromStrava() {
                if !refreshProgress.inProgress {
                    refreshProgress.start(asyncProgressModel: .mixed,
                                          title: "Fetching Strava updates...",
                                          maxStatus: 3)

                    StravaFetchLatestActivities(
                        completionHandler: {
                            refreshProgress.complete()
                            dataCache.refreshUI()
                            fetchComplete = false
                        },
                        failureCompletionHandler: {
                            refreshProgress.complete()
                            dataCache.refreshUI()
                            fetchComplete = false
                        },
                        asyncProgressNotifier: refreshProgress
                    ).execute()
                }
            }
            else {
                dataCache.refreshUI()
                fetchComplete = false
            }

            
#endif
        }

    }
}

struct ActivityHistoryView_Previews: PreviewProvider {
    
    static var navigationCoordinator = NavigationCoordinator()
    static var dataCache = DataCache()
    static var activityRecord = ActivityRecord()
    
    init() {

        ActivityHistoryView_Previews.dataCache.UIRecordSet.append(ActivityHistoryView_Previews.activityRecord)

    }
    
    static var previews: some View {
        ActivityHistoryView(navigationCoordinator: navigationCoordinator,
                            dataCache: dataCache)
    }
}
