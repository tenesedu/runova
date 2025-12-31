//
//  CityStep.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 20/2/25.
//

import SwiftUI

struct CityStep: View {
    @Binding var city: String
    
    var body: some View {
        VStack(spacing: 25) {
            AnimatedIcon(icon: "mappin.and.ellipse", namespace: Namespace().wrappedValue)
            
            FloatingTextField(title: "City", text: $city)
                .padding(.horizontal)
        }
    }
}

#Preview {
    @State var city = "Madrid"
    CityStep(city: $city)
}
