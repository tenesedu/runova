import SwiftUI

struct NewRunView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var distance: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Run Details")) {
                    TextField("Title", text: $title)
                    TextField("Distance (km)", text: $distance)
                        .keyboardType(.decimalPad)
                }
                
                Button("Save") {
                    // Add your save logic here
                    dismiss()
                }
                .disabled(title.isEmpty || distance.isEmpty)
            }
            .navigationTitle("New Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onTapGesture {
                // Dismiss the keyboard when tapping outside
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
} 