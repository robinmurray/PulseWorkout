//
//  FetchFailedView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 17/10/2024.
//

import SwiftUI

struct FetchFailedView: View {
    var body: some View {
        VStack {
            Image(systemName: "icloud.slash")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.yellow)
                
            Spacer()
            
            Text("Failed to fetch record from iCloud")
                .foregroundStyle(Color.yellow)
        }
    }
}

#Preview {
    FetchFailedView()
}
