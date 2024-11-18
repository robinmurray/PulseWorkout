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

    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .foregroundStyle(.foreground)
                Spacer()
            }
            HStack {
                Text(value)
                    .font(.system(.title3, design: .rounded).lowercaseSmallCaps())
                Spacer()
            }

            Divider()
        }

    }
}

#Preview {
    SummaryMetricView(title: "Metric Name", value: "10.0")
}
