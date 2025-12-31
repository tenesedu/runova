//
//  ValidationIndicator.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 20/2/25.
//

import SwiftUI

struct ValidationIndicator: View {
    var isValid: Bool
    
    var body: some View {
        Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundColor(isValid ? .green : .red)
    }
}

#Preview {
    ValidationIndicator(isValid: true)
}
