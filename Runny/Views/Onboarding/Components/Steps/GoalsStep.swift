//
//  GoalsStep.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 20/2/25.
//

import SwiftUI

struct GoalsStep: View {
    @Binding var goals: [String]
    let maxGoals = 3
    
    var body: some View {
        VStack(spacing: 25) {
            AnimatedIcon(icon: "flag.fill", namespace: Namespace().wrappedValue)
            
            VStack(spacing: 15) {
                ForEach(0..<maxGoals, id: \.self) { index in
                    FloatingTextField(
                        title: "Goal \(index + 1)",
                        text: Binding(
                            get: { goals.indices.contains(index) ? goals[index] : "" },
                            set: { newValue in
                                if goals.indices.contains(index) {
                                    goals[index] = newValue
                                } else if !newValue.isEmpty {
                                    goals.append(newValue)
                                }
                            }
                        )
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    @State var goals: [String] = ["100km", "climb a mountain", "run a marathon"]
    GoalsStep(goals: $goals)
}
