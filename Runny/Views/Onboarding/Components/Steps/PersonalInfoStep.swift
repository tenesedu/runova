//
//  PersonalInfoStep.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 20/2/25.
//

//  PersonalInfoStep.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 20/2/25.
//

import SwiftUI

struct PersonalInfoStep: View {
    @Binding var name: String
    @Binding var age: Int?
    var namespace: Namespace.ID
    
    var body: some View {
        VStack(spacing: 25) {
            AnimatedIcon(icon: "person.fill", namespace: namespace)
            
            // Full Name with padding and spacing
            VStack(spacing: 12) {  // Added some vertical space to separate
                FloatingTextField(title: "Full Name", text: $name)
                    .keyboardType(.namePhonePad)
                    .padding(.horizontal)  // Padding to keep it away from the edges
            }
            
            // Age Selector
            AgeSelector(age: $age)
                .padding(.horizontal)  // Padding to ensure it doesn't touch the edges
        }
        .padding(.top, 20) // Optional: Add some space at the top if needed
    }
}

#Preview {
    @State var name = "Eduardo Tenés Trillo"
    @State var age: Int? = 18
    @Namespace var namespace
    PersonalInfoStep(name: $name, age: $age, namespace: namespace)
}


struct AgeSelector: View {
    @Binding var age: Int?
    
    var body: some View {
        VStack(spacing: 16) {  // Added some space between the text and picker
            Text("Select Your Age")
                .font(.headline)
                .foregroundStyle(.gray)
            
            Picker("Age", selection: Binding(
                get: { age ?? 0 },
                set: { age = $0 == 0 ? nil : $0 }
            )) {
                Text("Prefer not to say").tag(0)
                ForEach(18...100, id: \.self) { age in
                    Text("\(age)").tag(age)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 200, height: 120)
            .clipped()
            .padding(.vertical) // Adds vertical padding around the picker
        }
        .padding(.horizontal) // Adds horizontal padding to the entire selector
    }
}

#Preview {
    @State var age: Int? = 18
    AgeSelector(age: $age)
}


