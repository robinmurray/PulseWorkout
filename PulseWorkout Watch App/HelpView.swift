//
//  HelpView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 21/12/2022.
//

import Foundation
import SwiftUI


struct HelpView: View {
    var body: some View {
        VStack{
            Text("Help")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.blue)
                .frame(height: 10)

        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
        
    }
}


struct HelpView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView()
    }
}


