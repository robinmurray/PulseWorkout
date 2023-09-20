//
//  ActivityListItemView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 30/06/2023.
//

import SwiftUI

struct ActivityListItemView: View {
    
    @State var activityRecord: ActivityRecord
    
    var body: some View {
        VStack {

            HStack {
                Text(activityRecord.name)
                    .foregroundStyle(.yellow)
                Spacer()
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
    
    static var activityRecord = ActivityRecord()
    
    static var previews: some View {
        ActivityListItemView(activityRecord: activityRecord)
    }
}

