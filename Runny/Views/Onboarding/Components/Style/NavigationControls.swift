//
//  NavigationControls.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 20/2/25.
//

import SwiftUI


struct NavigationControls: View {
    @Binding var currentStep: OnboardingView.OnboardingStep
    var isNextEnabled: Bool
    var onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            if currentStep != .personalInfo {
                Button(action: {
                    withAnimation(.spring()) {
                        currentStep = OnboardingView.OnboardingStep(rawValue: currentStep.rawValue - 1) ?? .personalInfo
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Capsule())
                }
            }
            
            Spacer()
            
            if currentStep == .location {
                Button(action: onSubmit) {
                    Text("Finish")
                        .padding()
                        .padding(.horizontal)
                        .foregroundColor(.white)
                        .background(isNextEnabled ? Color.purple : Color.gray)
                        .clipShape(Capsule())
                }
                .disabled(!isNextEnabled)
            } else {
                Button(action: {
                    withAnimation(.spring()) {
                        currentStep = OnboardingView.OnboardingStep(rawValue: currentStep.rawValue + 1) ?? .location
                    }
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(isNextEnabled ? Color.purple : Color.gray)
                    .clipShape(Capsule())
                }
                .disabled(!isNextEnabled)
            }
        }
        .padding()
        .padding(.bottom, 20)
    }
}

#Preview {
    @State var currentStep = OnboardingView.OnboardingStep.username
    
    NavigationControls(currentStep: $currentStep, isNextEnabled: true, onSubmit: {})
}

