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

    
    enum NavigationTarget {
        case ActivityDetailView
        case MapRouteView
    }
    
    
    var body: some View {
        
        #if os(iOS)
        ActivityHistoryHeaderView()
        #endif
        
        List {
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
            if !dataCache.fetching && !dataCache.fetchComplete {
              ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(.black)
                .foregroundColor(.red)
                .onAppear {
                    dataCache.fetchNextBlock()
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
                Image(systemName: "book.circle")
                    .foregroundColor(Color.black)
                    .background(Color.yellow)
                    .clipShape(Circle())
                Text("History")
                    .foregroundColor(Color.yellow)
            }
        }
    #endif
        .refreshable {
            dataCache.refreshUI()
        }

    }
}

struct ActivityHistoryView_Previews: PreviewProvider {
    
    static var navigationCoordinator = NavigationCoordinator()
    static var settingsManager = SettingsManager()
    static var dataCache = DataCache(settingsManager: settingsManager)
    static var activityRecord = ActivityRecord(settingsManager: settingsManager)
    
    init() {

        ActivityHistoryView_Previews.dataCache.UIRecordSet.append(ActivityHistoryView_Previews.activityRecord)

    }
    
    static var previews: some View {
        ActivityHistoryView(navigationCoordinator: navigationCoordinator,
                            dataCache: dataCache)
    }
}
