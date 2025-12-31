//
//  InterestsStep.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 20/2/25.
//

import SwiftUI

struct InterestsStep: View {
    @Binding var interests: [String]
    let availableInterests = ["Trail Running", "Marathon", "Social Running", "Sprinting"]
    
    var body: some View {
        VStack(spacing: 25) {
            AnimatedIcon(icon: "heart.fill", namespace: Namespace().wrappedValue)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
                    ForEach(availableInterests, id: \.self) { interest in
                        InterestChip(interest: interest, isSelected: interests.contains(interest)) {
                            if interests.contains(interest) {
                                interests.removeAll { $0 == interest }
                            } else {
                                interests.append(interest)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    @State var interests = ["Trail Running", "Marathon", "Social Running", "Sprinting"]
    
    InterestsStep(interests: $interests)
}
