//
//  CommunitySearchRow.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 29/1/25.
//

import SwiftUI

struct CommunitySearchRow: View {
    let community: Interest
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: community.backgroundImageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(community.name)
                    .font(.headline)
                Text(community.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

    
