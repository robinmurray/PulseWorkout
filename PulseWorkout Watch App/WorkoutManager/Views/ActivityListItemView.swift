//
//  ActivityListItemView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 30/06/2023.
//

import SwiftUI

struct ActivityListItemView: View {
    
    @State var activityRecord: ActivityRecord
    
    func stravaColour(stravaSaveStatus: Int) -> Color {
        switch stravaSaveStatus {
        case StravaSaveStatus.saved.rawValue:
            return Color.green
        case StravaSaveStatus.toSave.rawValue:
            return Color.orange
        default:
            return Color.clear
        }
    }
    
    var body: some View {
        VStack {

            HStack {
                Text(activityRecord.name)
                    .foregroundStyle(.yellow)
                Spacer()
                VStack {
                    if activityRecord.toSave {
                        Image(systemName: "icloud.slash.fill").foregroundColor(.red)
                    }
                    Image(systemName: "paperplane.circle").foregroundColor(
                        stravaColour(stravaSaveStatus: activityRecord.stravaSaveStatus))

                }

                
            }
            
            HStack {
                Text(activityRecord.startDateLocal.formatted(
                    Date.FormatStyle()
                        .day(.twoDigits)
                        .month(.abbreviated)
                        .hour(.defaultDigits(amPM: .omitted))
                        .minute(.twoDigits)
                        .hour(.conversationalDefaultDigits(amPM: .abbreviated))
                ))
                Spacer()
            }

        }

    }
}


struct ActivityListItemView_Previews: PreviewProvider {
    
    static var settingsManager = SettingsManager()
    static var activityRecord = ActivityRecord(settingsManager: settingsManager)
    
    static var previews: some View {
        ActivityListItemView(activityRecord: activityRecord)
    }
}

