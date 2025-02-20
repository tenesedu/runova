//
//  PersonalInfoStep.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 20/2/25.
//

import SwiftUI

struct PersonalInfoStep: View {
    @Binding var data: OnboardingData
    var namespace: Namespace.ID
    
    var body: some View {
        VStack(spacing: 25) {
            AnimatedIcon(icon: "person.fill", namespace: namespace)
            
            VStack(spacing: 15) {
                FloatingTextField(title: "Full Name", text: $data.name)
                    .keyboardType(.namePhonePad)
                
                AgeSelector(age: $data.age)
            }
            .padding(.horizontal)
        }
    }
}

#Preview {

}
