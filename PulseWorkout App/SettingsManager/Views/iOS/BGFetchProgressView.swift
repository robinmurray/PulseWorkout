//
//  StravaRefreshProgressView.swift
//  PulseWorkout Phone App
//
//  Created by Robin Murray on 06/10/2026.
//

import SwiftUI

struct BGFetchProgressView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var refreshParameters: BGFetchParameters
    let dateStyle = Date.FormatStyle
        .dateTime
            .day(.twoDigits)
            .month(.twoDigits)
            .year(.twoDigits)
            .hour(.twoDigits(amPM: .omitted))
            .minute(.twoDigits)
            .locale(Locale(identifier: "en_GB"))
    
    init(refreshParameters: BGFetchParameters) {
        self.refreshParameters = refreshParameters
    }
    
    var body: some View {
        
        VStack {
            HStack{
                Image("StravaIcon").resizable().frame(width: 30, height: 30)
                if refreshParameters.inProgress {
                    Text("Strava fetch status").foregroundColor(Color("StravaColor"))
                } else {
                    Text("Last Fetch Details")
                }
                Spacer()

            }

            
            HStack {
                if let submitDate = refreshParameters.submitDate {
                    Text("Submitted: ")
                    Spacer()
                    Text(submitDate.formatted(dateStyle))
                    
                }
            }
            .font(.footnote).foregroundColor(.gray)
            
            HStack {
                if let earliestFetchDate = refreshParameters.earliestFetchDate {
                    Text("Fetch back to: ")
                    Spacer()
                    Text(earliestFetchDate.formatted(dateStyle))

                }
            }
            .font(.footnote).foregroundColor(.gray)

            
            HStack {
                Text("Pages Completed :")
                Spacer()
                Text("\(refreshParameters.pagesCompleted)")
                    
            }
            .font(.footnote).foregroundColor(.gray)
            
            HStack {
                if refreshParameters.inProgress {
                    Text("Current page:")
                } else {
                    Text("Final page:")
                        
                }
                Spacer()
                
                if let pageStartDate = refreshParameters.pageStartDate {
                    Text(pageStartDate.formatted(dateStyle))
                }

            }
            .font(.footnote).foregroundColor(.gray)
            
            if refreshParameters.inProgress {
                HStack {
                    Text("Retries on current page:")
                    Spacer()
                    Text("\(refreshParameters.retryCount)")
                }
                .font(.footnote).foregroundColor(.gray)
 
            }
                

            HStack {
                Text("Total retries:")
                Spacer()
                Text("\(refreshParameters.totalRetries)")
            }
            .font(.footnote).foregroundColor(.gray)

            HStack {
                Text("Highest retries on a page:")
                Spacer()
                Text("\(refreshParameters.highestRetryCount)")
            }
            .font(.footnote).foregroundColor(.gray)

            HStack {
                if let completeDate = refreshParameters.completeDate {
                    Text("Completion \(completeDate.formatted(dateStyle)).")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }

            }
            
            
            if refreshParameters.cancelled {
                HStack {
                    if let cancelledDate = refreshParameters.cancelledDate {
                        Text("Cancelled at:")
                            .font(.footnote).foregroundColor(.gray)
                        Spacer()
                        Text(cancelledDate.formatted(dateStyle))
                            .font(.footnote).foregroundColor(.gray)

                    }
                }
            }


            if refreshParameters.inProgress {
                Button("Cancel Fetch") {
                    refreshParameters.cancelRequest()
                    dismiss()
                }
            }

        }
        .padding()


    }
}


#Preview {
    let refreshParameters = BGFetchParameters(userDefaultsKey: "stravaRefreshParameters")

    BGFetchProgressView(refreshParameters: refreshParameters)

}

