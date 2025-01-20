import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct RunCardView: View {
    let run: Run
    @State private var creatorProfileUrl: String = ""
    @State private var creatorName: String = ""
    @State private var showingParticipants = false
    @State private var participants: [UserApp] = []
    @State private var hasRequestedToJoin = false
    
    var body: some View {
        NavigationLink(destination: RunDetailView(run: run)) {
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
                        Text("Organizer")
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
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            fetchCreatorInfo()
            checkJoinRequest()
            fetchParticipants()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
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
    
    private func checkJoinRequest() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        hasRequestedToJoin = run.joinRequests.contains(userId)
    }
    
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
}
