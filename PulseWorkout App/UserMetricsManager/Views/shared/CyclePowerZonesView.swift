//
//  CyclePowerZonesView.swift
//  PulseWorkout
//
//  Created by Robin Murray on 21/04/2025.
//

import SwiftUI


struct CyclePowerZonesView: View {
    
    @ObservedObject var userPowerMetrics: UserPowerMetrics
    @State private var showingNewSheet = false
    
    var body: some View {
        Form {
            
            VStack {
                HStack {
                    Text("FTP:").fontWeight(.bold)
                    Spacer()
                    Text(powerFormatter(watts:Double(userPowerMetrics.currentFTP)))
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Functional Threshold Power - used as basis of power zones and training load.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }
            }

            PowerZonesView(userPowerMetrics: userPowerMetrics)
         
            HStack {
                Spacer()
                
                Button("Set New Power Zones...") {
                    showingNewSheet.toggle()
                }
                .buttonStyle(.borderedProminent)
                .sheet(isPresented: $showingNewSheet) {
                    CyclePowerZonesEditView(
                        userPowerMetrics: UserPowerMetrics(fromUserPowerMetrics: userPowerMetrics))
                }
                
                Spacer()
            }

            Text("History...")
        }
        .navigationTitle("Cycling Power Zones")
    }

}


struct CyclePowerZonesEditView: View {
    @ObservedObject var userPowerMetrics: UserPowerMetrics
    @State var initialFTP: Int
    @Environment(\.dismiss) var dismiss
    
    init(userPowerMetrics: UserPowerMetrics) {
        self.userPowerMetrics = userPowerMetrics
        self.initialFTP = userPowerMetrics.currentFTP
    }

    var body: some View {
        Form {
            VStack {
                HStack {
                    Text("FTP:").fontWeight(.bold)
                    Spacer()
                    
                    Stepper {
                        HStack {
                            Spacer()
                            Text(powerFormatter(watts:Double(userPowerMetrics.currentFTP)))
                                .fontWeight(.bold)
                        }
                        
                    } onIncrement: {
                        
                        userPowerMetrics.currentFTP += 1
                        userPowerMetrics.calculatePowerZonesFromFTP()
                        
                    } onDecrement: {
                        
                        userPowerMetrics.currentFTP -= 1
                        userPowerMetrics.calculatePowerZonesFromFTP()
                    }
                    
                }
                
                HStack {
                    Text("Functional Threshold Power - used as basis of power zones and training load.")
                        .font(.footnote).foregroundColor(.gray)
                    Spacer()
                }
            }

            PowerZonesView(userPowerMetrics: userPowerMetrics)

            
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("Save") {
                    userPowerMetrics.saveBackIfChanged()
                    dismiss()
                }
                .disabled(userPowerMetrics.currentFTP == initialFTP)
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            
        }



    }
}

#Preview {
    let userPowerMetrics = UserPowerMetrics()
    
    CyclePowerZonesView(userPowerMetrics: userPowerMetrics)
}

struct PowerZonesView: View {
    
    @ObservedObject var userPowerMetrics: UserPowerMetrics
    
    var body: some View {
        VStack {
            VStack {
                HStack {
                    Text("Low Aerobic").fontWeight(.bold)
                    Spacer()
                }.foregroundStyle(.blue)

                HStack {
                    Text("Zone 1: Active Recovery")
                    Spacer()
                    Text("\(userPowerMetrics.powerZoneLimits[0]) - \(userPowerMetrics.powerZoneLimits[1]) W")
                }

                HStack {
                    Text("Zone 2: Endurance")
                    Spacer()
                    Text("\(userPowerMetrics.powerZoneLimits[1]) - \(userPowerMetrics.powerZoneLimits[2]) W")
                }
            }
            .foregroundStyle(.gray)
            .background {
                Color.blue.opacity(0.2)
                    .ignoresSafeArea()
            }

            VStack {
                HStack {
                    Text("High Aerobic")
                        .fontWeight(.bold)
                    Spacer()
                }.foregroundStyle(.green)
                
                HStack {
                    Text("Zone 3: Tempo")
                    Spacer()
                    Text("\(userPowerMetrics.powerZoneLimits[2]) - \(userPowerMetrics.powerZoneLimits[3]) W")
                }
                 
                 HStack {
                     Text("Zone 4: Lactate Threshold")
                     Spacer()
                     Text("\(userPowerMetrics.powerZoneLimits[3]) - \(userPowerMetrics.powerZoneLimits[4]) W")
                 }
            }
            .foregroundStyle(.gray)
            .background {
                Color.green.opacity(0.2)
                    .ignoresSafeArea()
            }

            VStack {
                HStack {
                    Text("Anaerobic")
                        .fontWeight(.bold)
                    Spacer()
                }.foregroundStyle(.orange)

                HStack {
                    Text("Zone 5: VO2 Max")
                    Spacer()
                    Text("\(userPowerMetrics.powerZoneLimits[4]) - \(userPowerMetrics.powerZoneLimits[5]) W")
                }
                
                HStack {
                    Text("Zone 6: Anaerobic Capacity")
                    Spacer()
                    Text("> " + String(userPowerMetrics.powerZoneLimits[5]) + " W")
                }

                HStack {
                    Text("Zone 7: Neuromuscular Power")
                    Spacer()
                    Text("--")
                
                }

            }
            .foregroundStyle(.gray)
            .background {
                Color.orange.opacity(0.2)
                    .ignoresSafeArea()

            }
        }
        VStack {
            DatePicker(selection: $userPowerMetrics.metricsStartDate,
                       displayedComponents: [.date]) {
                Text("Effective from:")
                
            }
            .disabled(true)
            
            HStack {
                Text("Start date for these settings")
                    .font(.footnote).foregroundColor(.gray)
                Spacer()
            }

        }
    }
    
}

