//
//  LiveMetricCarouselItem.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 09/11/2023.
//

import SwiftUI

struct LiveMetricCarouselItem: View {
    
    var metric1: (image: String, text: String)
    var metric2: (image: String, text: String)

    
    var body: some View {
        // Distance & climbing
        VStack {
            HStack {
                Image(systemName: metric1.image)
                    .foregroundColor(Color.yellow)
                Text(metric1.text)
                    .padding(.trailing, 8)
                    .foregroundColor(Color.yellow)
                Spacer()
            }


            HStack {
                Image(systemName: metric2.image)
                    .foregroundColor(Color.yellow)
                Text(metric2.text)
                    .padding(.trailing, 8)
                    .foregroundColor(Color.yellow)
                    
                Spacer()
            }
        }


    }
}

struct LiveMetricCarouselItem_Previews: PreviewProvider {
    
    static var previews: some View {
        LiveMetricCarouselItem(metric1: (image: distanceIcon, text: "metric1 value"),
                               metric2: (image: ascentIcon, text: "metric2 value")
        )
    }
}
