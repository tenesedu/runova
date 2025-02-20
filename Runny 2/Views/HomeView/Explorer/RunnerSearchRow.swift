//
//  RunnerSearchRow.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 29/1/25.
//

import SwiftUI

struct RunnerSearchRow: View {
    let runner: Runner
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: runner.profileImageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(runner.name)
                    .font(.system(size: 16, weight: .medium))
                Text(runner.city)
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

