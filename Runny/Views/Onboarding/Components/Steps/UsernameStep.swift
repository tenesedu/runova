//
//  UsernameStep.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 20/2/25.
//

import SwiftUI

struct UsernameStep: View {
    @Binding var username: String
    @Binding var isAvailable: Bool
    var validateAction: () -> Void
    
    var body: some View {
        VStack(spacing: 25) {
            AnimatedIcon(icon: "at", namespace: Namespace().wrappedValue)
            
            VStack(spacing: 10) {
                HStack {
                    TextField("@username", text: $username)
                        .textFieldStyle(.plain)
                        .font(.title3)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: username, perform: { _ in
                            validateAction()
                        })
                    
                    ValidationIndicator(isValid: isAvailable)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .strokeBorder(isAvailable ? Color.green : Color.red, lineWidth: 2)
                )
                
                Text("Must be unique • 4-20 characters • Letters and numbers only")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}


#Preview {
    
}
