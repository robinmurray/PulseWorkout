//
//  SummaryMetricView.swift
//  PulseWorkout
//
//  Created by Robin Murray on 03/11/2024.
//

import SwiftUI

struct SummaryMetricView: View {
    var title: String
    var value: String
    var metric2title: String?
    var metric2value: String?

    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .foregroundStyle(.foreground)
                Spacer()
                
                if let t2 = metric2title {
                    Text(t2)
                        .foregroundStyle(.foreground)
                }
            }
            .padding(.horizontal)
            
            HStack {
                Text(value)
                    .font(.system(.title3, design: .rounded).lowercaseSmallCaps())
                Spacer()
                
                if let v2 = metric2value {
                    Text(v2)
                        .font(.system(.title3, design: .rounded).lowercaseSmallCaps())
                }
            }
            .padding(.horizontal)

            Divider()
        }

    }
}

#Preview {
    SummaryMetricView(title: "Metric Name", value: "10.0")
}
