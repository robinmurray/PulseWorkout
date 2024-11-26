//
//  ElapsedTimeView.swift
//  PulseWorkout Watch App
//
//  Created by Robin Murray on 11/01/2023.
//

import SwiftUI

struct ElapsedTimeView: View {
    var elapsedTime: TimeInterval = 0
    var showSeconds: Bool = true
    var showSubseconds: Bool = true
    @State private var timeFormatter = ElapsedTimeFormatter()

    var body: some View {
        Text(NSNumber(value: elapsedTime), formatter: timeFormatter)
            .fontWeight(.semibold)
            .onChange(of: showSubseconds) { oldState, newState in
                timeFormatter.showSubseconds = newState
            }
            .onAppear(perform: {
                timeFormatter.showSeconds = showSeconds
                timeFormatter.showSubseconds = showSubseconds
                }
            )
    }

}

class ElapsedTimeFormatter: Formatter {

    var showSeconds: Bool = true
    var showSubseconds = true

    
    var componentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    var noMinutesComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    override func string(for value: Any?) -> String? {
        guard let time = value as? TimeInterval else {
            return nil
        }

        if !showSeconds {
            guard let formattedString = noMinutesComponentsFormatter.string(from: time) else {
                return nil
            }
            
            return formattedString + ":__"
        }
        
        guard let formattedString = componentsFormatter.string(from: time) else {
            return nil
        }

        if showSubseconds {
            let hundredths = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
            let decimalSeparator = Locale.current.decimalSeparator ?? "."
            return String(format: "%@%@%0.2d", formattedString, decimalSeparator, hundredths)
        }

        return formattedString
    }
}

struct ElapsedTime_Previews: PreviewProvider {
    static var previews: some View {
        ElapsedTimeView()
    }
}
