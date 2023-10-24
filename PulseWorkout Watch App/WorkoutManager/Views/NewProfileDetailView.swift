//
//  NewProfileDetailView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 24/10/2023.
//

import SwiftUI

struct NewProfileDetailView: View {

    @ObservedObject var profileManager: ActivityProfiles
    @State var newProfile: ActivityProfile
    @State var cancelPressed = false
    @Environment(\.dismiss) private var dismiss
    
    init(profileManager: ActivityProfiles ) {
        self.profileManager = profileManager
        _newProfile = State(initialValue: profileManager.newProfile())
    }
    
    func cancel() {
        cancelPressed = true
        dismiss()
    }
    
    var body: some View {
        
        VStack {
            Form {

                ProfileDetailForm(profile: $newProfile)
                
                Section() {
                    Button(action: cancel) {
                        Text("Cancel")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.red)
                    .buttonStyle(PlainButtonStyle())

                }
            }

        }
        .navigationTitle("New Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if !cancelPressed {
                _ = profileManager.add(activityProfile: newProfile)
            }
        }
    }
}


struct NewProfileDetailView_Previews: PreviewProvider {
    
    static var profileManager = ActivityProfiles()
    
    static var previews: some View {
        NewProfileDetailView(profileManager: profileManager)
    }
}
