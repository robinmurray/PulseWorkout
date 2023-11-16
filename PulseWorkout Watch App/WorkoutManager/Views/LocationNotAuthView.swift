//
//  LocationNotAuthView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 14/11/2023.
//

import SwiftUI

struct LocationNotAuthView: View {
    var body: some View {
        VStack {
            Image(systemName: "location.slash.circle")
                .resizable()
                .scaledToFit()
                .foregroundStyle(Color.yellow)
                
            Spacer()
            
            Text("Location Services are not authorised and require authorisation")
                .foregroundStyle(Color.yellow)
        }

    }
}

struct LocationNotAuthView_Previews: PreviewProvider {
    static var previews: some View {
        LocationNotAuthView()
    }
}
