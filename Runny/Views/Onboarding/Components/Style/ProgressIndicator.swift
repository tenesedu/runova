//
//  ProgressIndicator.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 20/2/25.
//
import SwiftUI

struct ProgressIndicator: View {
    var currentStep: OnboardingView.OnboardingStep
    
    var body: some View {
        VStack(spacing: 10) {
            Text(currentStep.title)
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading)
            
            HStack(spacing: 4) {
                ForEach(OnboardingView.OnboardingStep.allCases, id: \.self) { step in
                    Capsule()
                        .fill(step.rawValue <= currentStep.rawValue ? Color.purple : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .frame(width: UIScreen.main.bounds.width / CGFloat(OnboardingView.OnboardingStep.allCases.count + 1))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    ProgressIndicator(currentStep: .personalInfo)
}
