//
//  LocationStep.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 20/2/25.
//

import SwiftUI

struct LocationStep: View {
    @Binding var locationEnabled: Bool
    
    var body: some View {
        VStack(spacing: 25) {
            AnimatedIcon(icon: "location.fill", namespace: Namespace().wrappedValue)
            
            Toggle("Enable Location Services", isOn: $locationEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .purple))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 5)
                )
                .padding(.horizontal)
        }
    }
}

#Preview {
    @State var locationEnabled = false
    LocationStep(locationEnabled: $locationEnabled)
}
