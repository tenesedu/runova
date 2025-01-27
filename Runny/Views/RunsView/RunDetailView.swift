import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import Foundation


struct RunDetailView: View {
    let run: Run
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) var presentationMode
    @State private var creatorProfileUrl: String = ""
    @State private var creatorName: String = ""
    @State private var participants: [UserApp] = []
    @State private var pendingRequests: [JoinRequest] = []
    @State private var hasRequestedToJoin = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingActionSheet = false
    @ObservedObject var viewModel: RunViewModel
    
    private var isCreator: Bool {
        run.createdBy == Auth.auth().currentUser?.uid
    }
    
    private var isParticipant: Bool {
        guard let userId = Auth.auth().currentUser?.uid else { return false }
        return run.currentParticipants.contains(userId)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Creator Info
                HStack {
                    AsyncImage(url: URL(string: creatorProfileUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(creatorName)
                            .font(.system(size: 18, weight: .semibold))
                        Text("Organizer")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Run Details
                VStack(alignment: .leading, spacing: 16) {
                    Text(run.name)
                        .font(.system(size: 24, weight: .bold))
                    
                    if !run.description.isEmpty {
                        Text(run.description)
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    
                    // Location and Time
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text(run.location)
                        }
                        HStack {
                            Image(systemName: "calendar")
                            Text(formatDateTime(run.time))
                        }
                    }
                    .foregroundColor(.gray)
                    
                    // Stats Card
                    HStack(spacing: 30) {
                        StatItem(title: "Distance", value: "\(String(format: "%.1f", run.distance))km", icon: "figure.run")
                        StatItem(title: "Pace", value: run.averagePace, icon: "stopwatch")
                        if let terrain = run.terrain {
                            StatItem(title: "Terrain", value: terrain, icon: "mountain.2")
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal)
                
                // Participants Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Participants (\(participants.count)/\(run.maxParticipants))")
                        .font(.system(size: 18, weight: .semibold))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(participants) { participant in
                                ParticipantView(user: participant)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Pending Requests Section (Only visible to creator)
                if isCreator && !pendingRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pending Requests (\(pendingRequests.count))")
                            .font(.system(size: 18, weight: .semibold))
                        
                        ForEach(pendingRequests) { requester in
                            HStack {
                                PendingRequestView(user: requester)
                                Spacer()
                                Button(action: { acceptRequest(for: requester) }) {
                                    Text("Accept")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.black)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Join Button (if not creator and not full)
                if !isCreator && !isParticipant && !run.isFull {
                    Button(action: {
                        viewModel.requestToJoin(run: run)
                    }) {
                        Text(viewModel.hasRequestedToJoin[run.id] == true ? "Requested" : "Request Join")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.hasRequestedToJoin[run.id] == true ? Color.gray : Color.black)
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.hasRequestedToJoin[run.id] == true)
                    .padding()
                }
                
                VStack(spacing: 12) {
                    if isCreator {
                        // Creator Actions
                        HStack(spacing: 16) {
                            Button(action: { showingEditSheet = true }) {
                                Label("Edit Run", systemImage: "pencil")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            Button(action: { showingDeleteAlert = true }) {
                                Label("Delete", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.1))
                                    .foregroundColor(.red)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    } else if isParticipant {
                        // Participant Actions
                        Button(action: unjoinRun) {
                            Text("Leave Run")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Run", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { deleteRun() }
        } message: {
            Text("Are you sure you want to delete this run? This action cannot be undone.")
        }
        .sheet(isPresented: $showingEditSheet) {
            EditRunView(run: run)
        }
        .alert(alertMessage, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        }
        .onAppear {
            verifyAndFetchData()
        }
    }
    
    private var menuButton: some View {
        Menu {
            Button(action: { showingEditSheet = true }) {
                Label("Edit Run", systemImage: "pencil")
            }
            Button(role: .destructive, action: { showingDeleteAlert = true }) {
                Label("Delete Run", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .padding(8)
                .contentShape(Rectangle())
        }
    }
    
    private func verifyAndFetchData() {
        // Verify run ID
        guard !run.id.isEmpty else {
            print("Error: Run ID is empty")
            return
        }
        
        // Verify creator ID
        guard !run.createdBy.isEmpty else {
            print("Error: Creator ID is empty")
            return
        }
        
        fetchCreatorInfo()
        fetchParticipants()
        fetchPendingRequests()
    }
    
    private func fetchCreatorInfo() {
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
    
    private func fetchParticipants() {
        participants.removeAll()
        let db = Firestore.firestore()

        // Fetch each participant's data
        for userId in run.currentParticipants {
            guard !userId.isEmpty else { continue }         
            // Make sure the document exists in Firestore
            db.collection("users").document(userId).getDocument { (snapshot, error) in
                if let error = error {
                    print("Error fetching participant: \(error.localizedDescription)")
                    return
                }

                // Ensure the document exists
                guard let data = snapshot?.data() else {
                    print("Participant document does not exist")
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

    
    private func fetchPendingRequests() {
        pendingRequests.removeAll()
        
        let db = Firestore.firestore()
        let joinRequestsRef = db.collection("runs").document(run.id)
                              .collection("joinRequests")
                              .whereField("status", isEqualTo: "pending")
        
        joinRequestsRef.getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching pending requests: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No pending requests found")
                return
            }
            
            for document in documents {
                let data = document.data()
             
                let userId = data["userId"] as? String ?? ""
                let userName = data["senderName"] as? String ?? ""
                let userImage = data["senderImage"] as? String ?? ""
                let status = data["status"] as? String ?? "pending"
                let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()

                
                let joinRequest = JoinRequest(
                    id: document.documentID,
                    status: status,
                    userId: userId,
                    userName: userName,
                    userImage: userImage,
                    timestamp: timestamp
                  
                )
                
                DispatchQueue.main.async {
                    pendingRequests.append(joinRequest)
                }
            }
        }
    }
    
    
    private func acceptRequest(for joinRequest: JoinRequest) {
        guard !isLoading else { return }
        isLoading = true
        
        let db = Firestore.firestore()
        let runRef = db.collection("runs").document(run.id)
        let joinRequestRef = runRef.collection("joinRequests").document(joinRequest.id)
        
        // Update the status of the join request to "accepted"
        joinRequestRef.updateData([
            "status": "accepted"
        ]) { error in
            if let error = error {
                isLoading = false
                alertMessage = "Error updating join request status: \(error.localizedDescription)"
                showingAlert = true
                return
            }
            
            // Add the user to the currentParticipants array
            runRef.updateData([
                "currentParticipants": FieldValue.arrayUnion([joinRequest.userId])
            ]) { error in
                isLoading = false
                if let error = error {
                    alertMessage = "Error adding user to participants: \(error.localizedDescription)"
                    showingAlert = true
                } else {
                    // Create notification for the user
                    let notification = UserNotification(
                        type: .joinRequestAccepted,
                        senderId: run.createdBy,
                        receiverId: joinRequest.userId,
                        senderName: creatorName,
                        senderProfileUrl: creatorProfileUrl,
                        runId: run.id
                    )
                    
                    // Send notification
                    NotificationManager().createNotification(notificationData: notification, receiverId: joinRequest.userId)
                    
                    // Remove from pending requests and refresh
                    pendingRequests.removeAll { $0.id == joinRequest.id }
                    fetchParticipants()
                }
            }
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func unjoinRun() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard !isLoading else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("runs").document(run.id).updateData([
            "currentParticipants": FieldValue.arrayRemove([userId])
        ]) { error in
            isLoading = false
            if let error = error {
                alertMessage = "Error leaving run: \(error.localizedDescription)"
                showingAlert = true
            } else {
                // Navigate back after successfully leaving
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func deleteRun() {
        guard isCreator else { return }
        guard !isLoading else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("runs").document(run.id).delete { error in
            isLoading = false
            if let error = error {
                alertMessage = "Error deleting run: \(error.localizedDescription)"
                showingAlert = true
            } else {
                // Navigate back after successful deletion
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct ParticipantView: View {
    let user: UserApp
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: user.profileImageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            Text(user.name)
                .font(.system(size: 12))
                .lineLimit(1)
        }
        .frame(width: 60)
    }
}

struct PendingRequestView: View {
    let user: JoinRequest
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: user.userImage)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.userName)
                    .font(.system(size: 16, weight: .medium))
                Text("Requested \(user.timestamp.timeAgo())")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
            Text(value)
                .font(.system(size: 16, weight: .semibold))
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
    }
}
