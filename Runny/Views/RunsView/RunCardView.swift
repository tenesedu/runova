import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct RunCardView: View {
    let run: Run
    @StateObject private var viewModel: RunViewModel
    @State private var creatorProfileUrl: String = ""
    @State private var creatorName: String = ""
    @State private var showingParticipants = false
    @State private var participants: [UserApp] = []
    
    init(run: Run, viewModel: RunViewModel) {
        self.run = run
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    private var isOrganizer: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return run.createdBy == currentUserId
    }
    
    private var isParticipant: Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return run.currentParticipants.contains(currentUserId)
    }
    
    private var buttonState: (text: String, isDisabled: Bool) {
        if isParticipant {
            return ("You're a Participant", true)
        } else if run.isFull && !isParticipant {
            return ("Run Full", true)

        }else if viewModel.hasRequestedToJoin[run.id] == true {
            return ("Request Pending", true)
        } else {
            return ("Request Join", false)
        }
    }
    
    var body: some View {
        NavigationLink(destination: RunDetailView(run: run, viewModel: viewModel)) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with creator info and time
                HStack(alignment: .center) {
                    AsyncImage(url: URL(string: creatorProfileUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(creatorName)
                            .font(.system(size: 16, weight: .medium))
                        Text(NSLocalizedString("Organizer", comment: ""))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formatDate(run.time))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text(formatTime(run.time))
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                
                // Run title and location
                VStack(alignment: .leading, spacing: 4) {
                    Text(run.name)
                        .font(.system(size: 18, weight: .semibold))
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.gray)
                        Text(run.location)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                }
                
                // Run details
                HStack(spacing: 20) {
                    // Distance
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.run")
                            Text("\(String(format: "%.1f", run.distance))km")
                        }
                        .font(.system(size: 14))
                        Text("Distance")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    // Pace
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "stopwatch")
                            Text(run.averagePace)
                        }
                        .font(.system(size: 14))
                        Text("Pace")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    // Participants
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2")
                            Text("\(run.currentParticipants.count)/\(run.maxParticipants)")
                        }
                        .font(.system(size: 14))
                        Text("Runners")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    
                    if run.terrain != nil {
                        // Terrain
                        VStack(spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "mountain.2")
                                Text(run.terrain ?? "")
                            }
                            .font(.system(size: 14))
                            Text("Terrain")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // Status Indicator and Join Button
                if run.status == .pending {
                    if isOrganizer {
                        // Show organizer badge instead of join button
                        HStack {
                            Spacer()
                            Text(NSLocalizedString("You're the organizer", comment: ""))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.orange)
                                )
                        }
                    } else {
                        // Show Request Join button for non-organizers
                        Button(action: {
                            viewModel.requestToJoin(run: run)
                        }) {
                            Text(buttonState.text)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.white)
                                .padding()
                                .background(
                                    buttonState.isDisabled ? Color.gray : Color.blue
                                )
                                .cornerRadius(10)
                        }
                        .disabled(buttonState.isDisabled)
                    }
                } else {
                    // Show status indicator for non-pending runs
                    HStack {
                        Spacer()
                        Text(run.status.rawValue.capitalized)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(statusBackgroundColor(for: run.status))
                            .foregroundColor(statusTextColor(for: run.status))
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(statusBorderColor(for: run.status), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            fetchCreatorInfo()
            fetchParticipants()
            viewModel.checkJoinRequestStatus(for: run)
        }
        .onDisappear {
            viewModel.stopListening(for: run.id)
        }
    }
    
    // Helper function to format date
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    // Helper function to format time
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Fetch creator info
    private func fetchCreatorInfo() {
        guard !run.createdBy.isEmpty else {
            print("Error: Creator ID is empty")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(run.createdBy).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching creator info: \(error.localizedDescription)")
                return
            }
            guard let data = snapshot?.data() else { return }
            creatorName = data["name"] as? String ?? "Unknown"
            creatorProfileUrl = data["profileImageUrl"] as? String ?? ""
        }
    }
    
    // Fetch participants
    private func fetchParticipants() {
        participants.removeAll() // Clear the existing participants
        let db = Firestore.firestore() // Initialize Firestore
        
        // Fetch each participant's data
        for userId in run.currentParticipants {
            guard !userId.isEmpty else { continue } // Skip empty user IDs
            
            // Fetch the document for each participant
            db.collection("users").document(userId).getDocument { (snapshot, error) in
                if let error = error {
                    print("Error fetching participant: \(error.localizedDescription)")
                    return
                }
                
                // Ensure the document exists and contains data
                guard let snapshot = snapshot, snapshot.exists, let data = snapshot.data() else {
                    print("Participant document does not exist or no data found.")
                    return
                }
                
                // Create a User object and append it to the participants array
                let user = UserApp(id: userId, data: data)
                
                // Update the participants array on the main thread
                DispatchQueue.main.async {
                    participants.append(user)
                }
            }
        }
    }
    
    // Helper function to get background color for status
    private func statusBackgroundColor(for status: RunStatus) -> Color {
        switch status {
        case .pending:
            return Color.gray.opacity(0.2)
        case .confirmed:
            return Color.green.opacity(0.2)
        case .canceled:
            return Color.red.opacity(0.2)
        case .finalized:
            return Color.blue.opacity(0.2)
        }
    }
    
    // Helper function to get text color for status
    private func statusTextColor(for status: RunStatus) -> Color {
        switch status {
        case .pending:
            return Color.gray
        case .confirmed:
            return Color.green
        case .canceled:
            return Color.red
        case .finalized:
            return Color.blue
        }
    }
    
    // Helper function to get border color for status
    private func statusBorderColor(for status: RunStatus) -> Color {
        switch status {
        case .pending:
            return Color.gray.opacity(0.5)
        case .confirmed:
            return Color.green.opacity(0.5)
        case .canceled:
            return Color.red.opacity(0.5)
        case .finalized:
            return Color.blue.opacity(0.5)
        }
    }
}

#Preview {
    let mockRun = Run(
        id: "run123",
        data: [
            "name": "Morning Jog",
            "description": "A relaxing jog around the park.",
            "time": Date(),
            "location": "Central Park",
            "distance": 5.0,
            "averagePace": "5:30/km",
            "maxParticipants": 10,
            "currentParticipants": ["user1", "user2"],
            "joinRequests": [],
            "createdBy": "user1",
            "terrain": "Flat",
            "status": "Pending"
        ]
    )
    
    return RunCardView(run: mockRun, viewModel: RunViewModel())
        .padding()
}
