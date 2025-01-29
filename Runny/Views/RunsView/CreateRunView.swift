import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateRunView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var dateTime: Date = Date()
    @State private var location: String = ""
    @State private var selectedParticipants: Int = 2
    @State private var distance: Double = 5.0
    @State private var selectedPaceMinutes: Int = 5
    @State private var selectedPaceSeconds: Int = 0
    @State private var terrain: String = "Road"
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var status: String = "pending"
    @State private var organizerId: String = ""
    
    @Binding var selectedSegment: Int
    
    let terrainTypes = ["Road", "Trail", "Track", "Mixed", "Beach", "Mountain"]
    let participantsRange = Array(2...50)
    let minutesRange = Array(3...15)
    let secondsRange = Array(0...59)
    let distanceRange = Array(stride(from: 1.0, through: 100.0, by: 0.5))
    
var body: some View {
    NavigationView {
        Form {
            Section {
                TextField("Run Name", text: $name)
                    .font(.system(size: 18, weight: .medium))
                
                TextEditor(text: $description)
                    .frame(height: 100)
                    .font(.system(size: 16))
                    .placeholder(when: description.isEmpty) {
                        Text("Description")
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
            }
            
            Section {
                DatePicker("Date & Time", selection: $dateTime, in: Date()...)
                    .datePickerStyle(.compact)
                    .tint(.black)
                
                TextField("Location", text: $location)
                    .font(.system(size: 16))
            }
            
            Section {
                // Distance Picker
                HStack {
                    Text("Distance")
                        .foregroundColor(.gray)
                    Spacer()
                    Picker("", selection: $distance) {
                        ForEach(distanceRange, id: \.self) { km in
                            Text("\(String(format: "%.1f", km)) km").tag(km)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 100)
                    .clipped()
                }
                
                // Pace Selection
                HStack {
                    Text("Average Pace")
                        .foregroundColor(.gray)
                    Spacer()
                    HStack(spacing: 0) {
                        Picker("", selection: $selectedPaceMinutes) {
                            ForEach(minutesRange, id: \.self) { minute in
                                Text("\(minute)").tag(minute)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 50)
                        .clipped()
                        
                        Text(":")
                            .font(.system(size: 18, weight: .medium))
                            .padding(.horizontal, 4)
                        
                        Picker("", selection: $selectedPaceSeconds) {
                            ForEach(secondsRange, id: \.self) { second in
                                Text(String(format: "%02d", second)).tag(second)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(width: 50)
                        .clipped()
                    }
                }
                
                // Terrain Selection
                HStack {
                    Text("Terrain")
                        .foregroundColor(.gray)
                    Spacer()
                    Menu {
                        ForEach(terrainTypes, id: \.self) { terrainType in
                            Button(action: {
                                terrain = terrainType
                            }) {
                                HStack {
                                    Text(terrainType)
                                    if terrain == terrainType {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }                        }
                    } label: {
                        HStack {
                            Text(terrain)
                                .foregroundColor(.black)
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Participants Selection
                HStack {
                    Text("Max Participants")
                        .foregroundColor(.gray)
                    Spacer()
                    Picker("", selection: $selectedParticipants) {
                        ForEach(participantsRange, id: \.self) { count in
                            Text("\(count)").tag(count)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 100)
                    .clipped()
                }
            }
            
            Section {
                Button(action: createRun) {
                    Text("Create Run")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(name.isEmpty || location.isEmpty ? Color.gray : Color.black)
                        )
                }
                .disabled(name.isEmpty || location.isEmpty)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Create Run")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Add the "Cancelar" button
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    selectedSegment = 2
                    dismiss()
                }
                .foregroundColor(.black)
            }
        }
        .navigationBarBackButtonHidden(true) 
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .tint(.black)
    }
    .navigationViewStyle(.stack) 
}
    
    private func createRun() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let runData: [String: Any] = [
            "name": name,
            "description": description,
            "time": dateTime,
            "location": location,
            "maxParticipants": selectedParticipants,
            "currentParticipants": [userId],
            "distance": distance,
            "averagePace": "\(selectedPaceMinutes):\(String(format: "%02d", selectedPaceSeconds))",
            "terrain": terrain,
            "createdBy": userId,
            "timestamp": FieldValue.serverTimestamp(),
            "status": status
        ]
        
        db.collection("runs").addDocument(data: runData) { error in
            if let error = error {
                alertMessage = "Error creating run: \(error.localizedDescription)"
                showAlert = true
            } else {
                dismiss()
            }
        }
    }
}

// Helper extension for placeholder text in TextEditor
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
} 
