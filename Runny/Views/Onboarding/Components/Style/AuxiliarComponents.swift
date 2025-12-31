//
//  AuxiliarComponents.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 20/2/25.
//

import SwiftUI

struct AnimatedIcon: View {
    var icon: String
    var namespace: Namespace.ID
    
    var body: some View {
        Image(systemName: icon)
            .resizable()
            .scaledToFit()
            .frame(width: 50, height: 50)
            .foregroundColor(.purple)
            .matchedGeometryEffect(id: icon, in: namespace)
    }
}


struct FloatingTextField: View {
    var title: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            TextField("", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}


// MARK: - Componentes Auxiliares
struct InterestChip: View {
    let interest: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(interest)
                .padding(10)
                .background(isSelected ? Color.purple : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}



#Preview {
    
}
