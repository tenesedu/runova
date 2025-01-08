import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct CreateView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var dateTime: Date = Date()
    @State private var location: String = ""
    @State private var selectedParticipants: Int = 2
    @State private var distance: Double = 0.0
    @State private var selectedPaceMinutes: Int = 5
    @State private var selectedPaceSeconds: Int = 0
    @State private var terrain: String = "Road"
    @State private var alertMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var showSuccessMessage: Bool = false
    
    let terrainTypes = ["Road", "Trail", "Track", "Mixed", "Beach", "Mountain"]
    let participantsRange = Array(2...50)
    let minutesRange = Array(3...15)
    let secondsRange = Array(0...59)
    
    var formattedPace: String {
        String(format: "%d:%02d", selectedPaceMinutes, selectedPaceSeconds)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "figure.run.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Create New Run")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        .padding(.top, 20)
                        
                        // Form Sections
                        Group {
                            // Basic Info Section
                            FormSection(title: "BASIC INFORMATION", systemImage: "info.circle.fill") {
                                CustomTextField(title: "Run Name", text: $name, placeholder: "Morning Run")
                                    .textFieldStyle(RoundedTextFieldStyle())
                                
                                CustomTextField(title: "Description", text: $description, isMultiline: true, placeholder: "Describe your run...")
                            }
                            
                            // Date and Time Section
                            FormSection(title: "DATE & TIME", systemImage: "calendar.circle.fill") {
                                DatePicker("Select", selection: $dateTime, displayedComponents: [.date, .hourAndMinute])
                                    .datePickerStyle(GraphicalDatePickerStyle())
                                    .tint(.blue)
                            }
                            
                            // Location Section
                            FormSection(title: "LOCATION", systemImage: "mappin.circle.fill") {
                                CustomTextField(title: "Meeting Point", text: $location, placeholder: "Enter location...")
                                    .textFieldStyle(RoundedTextFieldStyle())
                            }
                            
                            // Run Details Section
                            FormSection(title: "RUN DETAILS", systemImage: "figure.run.circle.fill") {
                                // Participants
                                LabeledContent("Max Participants") {
                                    Picker("", selection: $selectedParticipants) {
                                        ForEach(participantsRange, id: \.self) { number in
                                            Text("\(number)").tag(number)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(width: 80)
                                }
                                
                                Divider()
                                
                                // Distance
                                CustomTextField(title: "Distance (km)", 
                                             value: $distance,
                                             formatter: NumberFormatter())
                                    .textFieldStyle(RoundedTextFieldStyle())
                                
                                Divider()
                                
                                // Pace
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Average Pace")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    HStack {
                                        Picker("Minutes", selection: $selectedPaceMinutes) {
                                            ForEach(minutesRange, id: \.self) { minute in
                                                Text("\(minute)").tag(minute)
                                            }
                                        }
                                        .pickerStyle(WheelPickerStyle())
                                        .frame(width: 80)
                                        
                                        Text(":")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        
                                        Picker("Seconds", selection: $selectedPaceSeconds) {
                                            ForEach(secondsRange, id: \.self) { second in
                                                Text(String(format: "%02d", second)).tag(second)
                                            }
                                        }
                                        .pickerStyle(WheelPickerStyle())
                                        .frame(width: 80)
                                        
                                        Text("min/km")
                                            .foregroundColor(.gray)
                                    }
                                }
                                
                                Divider()
                                
                                // Terrain
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Terrain Type")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                    
                                    HStack(spacing: 10) {
                                        ForEach(terrainTypes, id: \.self) { type in
                                            TerrainButton(type: type, 
                                                        isSelected: type == terrain,
                                                        action: { terrain = type })
                                        }
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Create Button
                        Button(action: createRun) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Create Run")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(colors: [.blue, .blue.opacity(0.8)],
                                             startPoint: .leading,
                                             endPoint: .trailing)
                            )
                            .cornerRadius(15)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("Success", isPresented: $showSuccessMessage) {
                Button("OK", role: .cancel) {
                    resetFields()
                }
            } message: {
                Text("Run created successfully!")
            }
        }
    }

    private func createRun() {
        guard !name.isEmpty, !description.isEmpty, !location.isEmpty,
              !terrain.isEmpty, distance > 0 else {
            alertMessage = "Please fill in all fields."
            showAlert = true
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else { return }

        let runData: [String: Any] = [
            "name": name,
            "description": description,
            "time": Timestamp(date: dateTime),
            "location": location,
            "maxParticipants": selectedParticipants,
            "currentParticipants": [userId],
            "distance": distance,
            "averagePace": formattedPace,
            "terrain": terrain,
            "createdBy": userId,
            "createdAt": FieldValue.serverTimestamp()
        ]

        let db = Firestore.firestore()
        db.collection("runs").addDocument(data: runData) { error in
            if let error = error {
                alertMessage = "Error creating run: \(error.localizedDescription)"
                showAlert = true
            } else {
                showSuccessMessage = true
            }
        }
    }

    private func resetFields() {
        name = ""
        description = ""
        dateTime = Date()
        location = ""
        selectedParticipants = 2
        distance = 0.0
        selectedPaceMinutes = 5
        selectedPaceSeconds = 0
        terrain = "Road"
    }
}

// Helper Views
struct FormSection<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content
    
    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 15) {
                content
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.05), radius: 5)
        }
    }
}

struct TerrainButton: View {
    let type: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(type)
                .font(.footnote)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
    }
}

struct CustomTextField: View {
    let title: String
    var text: Binding<String>? = nil
    var value: Binding<Double>? = nil
    var formatter: NumberFormatter? = nil
    var isMultiline: Bool = false
    var placeholder: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            if let text = text {
                if isMultiline {
                    TextEditor(text: text)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                } else {
                    TextField(placeholder, text: text)
                }
            } else if let value = value, let formatter = formatter {
                TextField(placeholder, value: value, formatter: formatter)
                    .keyboardType(.decimalPad)
            }
        }
    }
} 
