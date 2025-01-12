//
//  EmptyStateView.swift
//  Runny
//
//  Created by Joaquín Tenés on 12/1/25.
//

import SwiftUI

struct EmptyStateView: View {
    let message: String
    let systemImage: String
    let description: String?
    
    init(
        message: String,
        systemImage: String = "message.circle",
        description: String? = nil
    ) {
        self.message = message
        self.systemImage = systemImage
        self.description = description
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: systemImage)
                .font(.system(size: 70))
                .foregroundColor(.blue.opacity(0.3))
            
            Text(message)
                .font(.headline)
                .foregroundColor(.gray)
            
            if let description = description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}
