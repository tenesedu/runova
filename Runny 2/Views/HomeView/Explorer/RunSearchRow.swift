//
//  RunSearchRow.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 29/1/25.
//

import SwiftUI

struct RunSearchRow: View {
    let run: Run
    
    var body: some View {
        HStack(spacing: 12) {
            // Run Icon or Image
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "figure.run")
                    .foregroundColor(.blue)
            }
            
            // Run Info
            VStack(alignment: .leading, spacing: 4) {
                Text(run.name)
                    .font(.system(size: 16, weight: .medium))
                
                Text(run.location)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
