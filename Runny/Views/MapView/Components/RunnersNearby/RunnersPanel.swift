//
//  RunnersPanel.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 21/1/25.
//

import SwiftUI
import CoreLocation

struct RunnersPanel: View {
    let runnersInRange: [UserApp]
    let locationManager: LocationManager
    let onUserSelected: (UserApp) -> Void
    let selectedRange: Double

    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(String(format: NSLocalizedString("%d Runners within %d km", comment: ""), runnersInRange.count, Int(selectedRange)))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !runnersInRange.isEmpty {
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            if runnersInRange.isEmpty {
                HStack {
                    Spacer()
                    Text(NSLocalizedString("No runners in your area", comment: ""))
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(runnersInRange) { user in
                            NearbyRunnerCard(user: user, locationManager: locationManager, action: {
                                onUserSelected(user)
                            })
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
        )
        .frame(height: runnersInRange.isEmpty ? 70 : (isExpanded ? 200 : 70))
    }
}

