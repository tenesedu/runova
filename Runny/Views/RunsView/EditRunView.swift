import SwiftUI
import FirebaseFirestore

struct EditRunView: View {
    let run: Run
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var description: String
    @State private var location: String
    @State private var date: Date
    @State private var distance: Double
    @State private var averagePace: String
    @State private var maxParticipants: Int
    @State private var terrain: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    init(run: Run) {
        self.run = run
        _name = State(initialValue: run.name)
        _description = State(initialValue: run.description)
        _location = State(initialValue: run.location)
        _date = State(initialValue: run.time)
        _distance = State(initialValue: run.distance)
        _averagePace = State(initialValue: run.averagePace)
        _maxParticipants = State(initialValue: run.maxParticipants)
        _terrain = State(initialValue: run.terrain ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Run Details")) {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description)
                    TextField("Location", text: $location)
                }
                
                Section(header: Text("Time & Distance")) {
                    DatePicker("Date & Time", selection: $date)
                    HStack {
                        Text("Distance (km)")
                        Spacer()
                        TextField("Distance", value: $distance, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    TextField("Average Pace", text: $averagePace)
                }
                
                Section(header: Text("Additional Info")) {
                    Stepper("Max Participants: \(maxParticipants)", value: $maxParticipants, in: 2...50)
                    TextField("Terrain", text: $terrain)
                }
            }
            .navigationTitle("Edit Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { updateRun() }
                        .disabled(isLoading)
                }
            }
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            }
        }
    }
    
    private func updateRun() {
        guard !isLoading else { return }
        isLoading = true
        
        let db = Firestore.firestore()
        let runData: [String: Any] = [
            "name": name,
            "description": description,
            "location": location,
            "time": Timestamp(date: date),
            "distance": distance,
            "averagePace": averagePace,
            "maxParticipants": maxParticipants,
            "terrain": terrain
        ]
        
        db.collection("runs").document(run.id).updateData(runData) { error in
            isLoading = false
            if let error = error {
                alertMessage = "Error updating run: \(error.localizedDescription)"
                showingAlert = true
            } else {
                dismiss()
            }
        }
    }
} 