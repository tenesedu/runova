import SwiftUI

struct MessageInputField: View {
    @Binding var text: String
    let onSend: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            TextField(NSLocalizedString("Type a message...", comment: ""), text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($isFocused)
                .submitLabel(.send)
                .onSubmit {
                    if !text.isEmpty {
                        isFocused = false
                        onSend()
                    }
                }
            
            Button(action: {
                isFocused = false
                onSend()
            }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .padding(10)
                    .background(text.isEmpty ? Color.gray : Color.blue)
                    .clipShape(Circle())
            }
            .disabled(text.isEmpty)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 5, y: -5)
    }
}

struct MessageInputField_Previews: PreviewProvider {
    @State static var text: String = ""
    
    static var previews: some View {
        MessageInputField(text: $text, onSend: {
            print("Message sent: \(text)")
        })
    }
}
