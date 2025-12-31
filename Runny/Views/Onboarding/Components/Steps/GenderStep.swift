//
//  GenderStep.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 20/2/25.
//

import SwiftUI

struct GenderStep: View {
    @Binding var gender: String
    let options = ["Male", "Female", "Other", "Prefer not to say"]
    
    var body: some View {
        VStack(spacing: 25) {
            AnimatedIcon(icon: "person.2.fill", namespace: Namespace().wrappedValue)
            
            Picker("Gender", selection: $gender) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 5)
            )
        }
    }
}

#Preview {
    @State var gender = "Male"
    GenderStep(gender: $gender)
}
