//
//  ActivityHeaderView.swift
//  PulseWorkout
//
//  Created by Robin Murray on 03/11/2024.
//

import SwiftUI

struct ActivityHeaderView: View {

    @ObservedObject var activityRecord: ActivityRecord

    var body: some View {
        
        VStack(alignment: .leading) {
            HStack {
                Text(activityRecord.name)
                    .foregroundStyle(.yellow)
                Spacer()
            }

            HStack {
                Text(activityRecord.startDateLocal.formatted(
                    Date.FormatStyle(timeZone: TimeZone(identifier: "GMT")!)
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
#Preview {

    let record = ActivityRecord()
    
    ActivityHeaderView(activityRecord: record)
}
