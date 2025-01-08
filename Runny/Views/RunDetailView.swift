import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RunDetailView: View {
    let run: Run
    @State private var creatorProfile: UserProfile?
    @State private var showingJoinAlert = false
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @Environment(\.dismiss) private var dismiss
    @State private var joinRequests: [JoinRequest] = []
    @State private var showingRequests = false
    @State private var participants: [UserProfile] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Header
                VStack(spacing: 12) {
                    Text(run.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(run.description)
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Key Info Cards
                HStack(spacing: 15) {
                    InfoCard(title: "Distance", value: String(format: "%.1f km", run.distance), icon: "figure.run")
                    InfoCard(title: "Pace", value: run.averagePace, icon: "speedometer")
                }
                .padding(.horizontal)
                
                // Details Section
                VStack(alignment: .leading, spacing: 20) {
                    SectionTitle(text: "Run Details")
                    
                    VStack(spacing: 15) {
                        DetailRow(icon: "calendar", title: "Date", value: run.time.formatted(date: .long, time: .shortened))
                        DetailRow(icon: "mappin.circle.fill", title: "Location", value: run.location)
                        DetailRow(icon: "mountain.2.fill", title: "Terrain", value: run.terrain)
                        DetailRow(icon: "person.3.fill", title: "Participants", value: "\(run.currentParticipants.count)/\(run.maxParticipants)")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.05), radius: 5)
                }
                .padding(.horizontal)
                
                // Creator Info Section
                if let creator = creatorProfile {
                    VStack(alignment: .leading, spacing: 20) {
                        SectionTitle(text: "Created by")
                        
                        HStack(spacing: 15) {
                            if let image = creator.profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                    .overlay(Text("👤").font(.system(size: 30)))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(creator.name)
                                    .font(.headline)
                                Text(creator.city)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(15)
                        .shadow(color: Color.black.opacity(0.05), radius: 5)
                    }
                    .padding(.horizontal)
                }
                
                if isCreator {
                    VStack(alignment: .leading, spacing: 20) {
                        SectionTitle(text: "Join Requests")
                        
                        if joinRequests.isEmpty {
                            Text("No pending requests")
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemBackground))
                                .cornerRadius(15)
                        } else {
                            ForEach(joinRequests) { request in
                                JoinRequestRow(request: request, onAccept: {
                                    acceptRequest(request)
                                }, onDecline: {
                                    declineRequest(request)
                                })
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Participants Section
                VStack(alignment: .leading, spacing: 20) {
                    SectionTitle(text: "Participants (\(participants.count))")
                    
                    if participants.isEmpty {
                        Text("No participants yet")
                            .foregroundColor(.gray)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemBackground))
                            .cornerRadius(15)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(participants) { participant in
                                ParticipantRow(participant: participant)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Join Button
                if !isCreator {
                    Button(action: requestToJoin) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Request to Join")
                        }
                        .fontWeight(.semibold)
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
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Join Run", isPresented: $showingJoinAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Join") {
                sendJoinRequest()
            }
        } message: {
            Text("Would you like to join this run?")
        }
        .onAppear {
            fetchCreatorProfile()
            fetchJoinRequests()
            fetchParticipants()
        }
    }
    
    private var isCreator: Bool {
        run.createdBy == Auth.auth().currentUser?.uid
    }
    
    private func fetchCreatorProfile() {
        let db = Firestore.firestore()
        db.collection("users").document(run.createdBy).getDocument { snapshot, error in
            if let document = snapshot,
               let data = document.data() {
                self.creatorProfile = UserProfile(
                    id: document.documentID,
                    name: data["name"] as? String ?? "Unknown",
                    age: data["age"] as? String ?? "N/A",
                    averagePace: data["averagePace"] as? String ?? "N/A",
                    city: data["city"] as? String ?? "Unknown",
                    profileImageUrl: data["profileImageUrl"] as? String ?? "",
                    gender: data["gender"] as? String ?? "Not specified"
                )
                
                if let profileImageUrl = data["profileImageUrl"] as? String,
                   let url = URL(string: profileImageUrl) {
                    URLSession.shared.dataTask(with: url) { data, _, _ in
                        if let data = data, let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                self.creatorProfile?.profileImage = image
                            }
                        }
                    }.resume()
                }
            }
        }
    }
    
    private func requestToJoin() {
        guard !run.currentParticipants.contains(where: { $0 == Auth.auth().currentUser?.uid }) else {
            alertMessage = "You are already part of this run"
            showingAlert = true
            return
        }
        
        if run.currentParticipants.count >= run.maxParticipants {
            alertMessage = "This run is already full"
            showingAlert = true
            return
        }
        
        showingJoinAlert = true
    }
    
    private func sendJoinRequest() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let joinRequest = [
            "runId": run.id,
            "userId": userId,
            "status": "pending",
            "timestamp": FieldValue.serverTimestamp()
        ] as [String : Any]
        
        db.collection("joinRequests").addDocument(data: joinRequest) { error in
            if let error = error {
                alertMessage = "Error sending request: \(error.localizedDescription)"
                showingAlert = true
            } else {
                alertMessage = "Join request sent successfully!"
                showingAlert = true
            }
        }
    }
    
    private func fetchJoinRequests() {
        guard isCreator else { return }
        
        let db = Firestore.firestore()
        db.collection("joinRequests")
            .whereField("runId", isEqualTo: run.id)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                
                // Fetch user details for each request
                let group = DispatchGroup()
                var requests: [JoinRequest] = []
                
                for document in documents {
                    let data = document.data()
                    guard let userId = data["userId"] as? String else { continue }
                    
                    group.enter()
                    db.collection("users").document(userId).getDocument { snapshot, error in
                        defer { group.leave() }
                        
                        if let userData = snapshot?.data() {
                            let request = JoinRequest(
                                id: document.documentID,
                                userId: userId,
                                userName: userData["name"] as? String ?? "Unknown",
                                userImage: userData["profileImageUrl"] as? String,
                                timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                            )
                            requests.append(request)
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    self.joinRequests = requests.sorted { $0.timestamp < $1.timestamp }
                }
            }
    }
    
    private func acceptRequest(_ request: JoinRequest) {
        let db = Firestore.firestore()
        
        // Update the request status
        db.collection("joinRequests").document(request.id).updateData([
            "status": "accepted"
        ])
        
        // Add user to run participants
        db.collection("runs").document(run.id).updateData([
            "currentParticipants": FieldValue.arrayUnion([request.userId])
        ]) { error in
            if error == nil {
                // Refresh participants list
                fetchParticipants()
            }
        }
    }
    
    private func declineRequest(_ request: JoinRequest) {
        let db = Firestore.firestore()
        db.collection("joinRequests").document(request.id).updateData([
            "status": "declined"
        ])
    }
    
    private func fetchParticipants() {
        participants = [] // Reset the list before fetching
        let db = Firestore.firestore()
        
        // Create a dispatch group to handle multiple async calls
        let group = DispatchGroup()
        
        // Fetch all participants' profiles
        for userId in run.currentParticipants {
            group.enter()
            db.collection("users").document(userId).getDocument { snapshot, error in
                defer { group.leave() }
                
                if let document = snapshot,
                   let data = document.data() {
                    var participant = UserProfile(
                        id: document.documentID,
                        name: data["name"] as? String ?? "Unknown",
                        age: data["age"] as? String ?? "N/A",
                        averagePace: data["averagePace"] as? String ?? "N/A",
                        city: data["city"] as? String ?? "Unknown",
                        profileImageUrl: data["profileImageUrl"] as? String ?? "",
                        gender: data["gender"] as? String ?? "Not specified"
                    )
                    
                    // Load profile image if available
                    if let profileImageUrl = data["profileImageUrl"] as? String,
                       let url = URL(string: profileImageUrl) {
                        URLSession.shared.dataTask(with: url) { data, _, _ in
                            if let data = data, let image = UIImage(data: data) {
                                DispatchQueue.main.async {
                                    participant.profileImage = image
                                    if let index = self.participants.firstIndex(where: { $0.id == participant.id }) {
                                        self.participants[index] = participant
                                    } else {
                                        self.participants.append(participant)
                                    }
                                }
                            }
                        }.resume()
                    } else {
                        DispatchQueue.main.async {
                            if !self.participants.contains(where: { $0.id == participant.id }) {
                                self.participants.append(participant)
                            }
                        }
                    }
                }
            }
        }
        
        // After all participants are fetched, sort them
        group.notify(queue: .main) {
            self.participants.sort { $0.name < $1.name }
        }
    }
    
    private func joinRun() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let joinRequestData: [String: Any] = [
            "userId": currentUserId,
            "runId": run.id,
            "status": "pending",
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        db.collection("joinRequests").addDocument(data: joinRequestData) { error in
            if let error = error {
                print("Error creating join request: \(error.localizedDescription)")
            } else {
                print("Join request created successfully")
                // Update UI or show confirmation
            }
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
}

struct SectionTitle: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.gray)
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
    }
}
