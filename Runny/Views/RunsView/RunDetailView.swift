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
            VStack(alignment: .leading, spacing: 24) {
                // Creator Info Card
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        AsyncImage(url: URL(string: creatorProfileUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(creatorName)
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text(NSLocalizedString("Organizer", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    
                    // Run Title and Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(run.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if !run.description.isEmpty {
                            Text(run.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10)
                
                // Details Card
                VStack(spacing: 20) {
                    // Location and Time
                    VStack(alignment: .leading, spacing: 16) {
                        DetailRow(icon: "location.fill", text: run.location)
                        DetailRow(icon: "calendar", text: formatDateTime(run.time))
                    }
                    
                    Divider()
                    
                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        StatItem(
                            title: NSLocalizedString("Distance", comment: "Run distance stat"), 
                            value: "\(String(format: "%.1f", run.distance))km", 
                            icon: "figure.run"
                        )
                        StatItem(
                            title: NSLocalizedString("Pace", comment: "Run pace stat"), 
                            value: run.averagePace, 
                            icon: "stopwatch"
                        )
                        if let terrain = run.terrain {
                            StatItem(
                                title: NSLocalizedString("Terrain", comment: "Run terrain stat"), 
                                value: terrain, 
                                icon: "mountain.2"
                            )
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10)
                
                // Participants Section
                VStack(alignment: .leading, spacing: 16) {
                    Text(NSLocalizedString("Participants", comment: "") + " (\(participants.count)/\(run.maxParticipants))")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(participants) { participant in
                                ParticipantView(user: participant)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 10)
                
                // Pending Requests Section
                if isCreator && !pendingRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(NSLocalizedString("Pending Requests", comment: "") + " (\(pendingRequests.count))")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        ForEach(pendingRequests) { requester in
                            HStack {
                                PendingRequestView(user: requester)
                                Spacer()
                                Button(action: { acceptRequest(for: requester) }) {
                                    Text(NSLocalizedString("Accept", comment: "Accept join request button"))
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                }
                            }
                            Divider()
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 10)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    if !isCreator && !isParticipant && !run.isFull {
                        Button(action: {
                            viewModel.requestToJoin(run: run)
                        }) {
                            Text(viewModel.hasRequestedToJoin[run.id] == true ? 
                                NSLocalizedString("Requested", comment: "") : 
                                NSLocalizedString("Request Join", comment: ""))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(viewModel.hasRequestedToJoin[run.id] == true ? Color.gray : Color.blue)
                                .cornerRadius(12)
                        }
                        .disabled(viewModel.hasRequestedToJoin[run.id] == true)
                    }
                    
                    if isCreator {
                        HStack(spacing: 16) {
                            Button(action: { showingEditSheet = true }) {
                                Label(NSLocalizedString("Edit Run", comment: ""), systemImage: "pencil")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                            }
                            
                            Button(action: { showingDeleteAlert = true }) {
                                Label(NSLocalizedString("Delete", comment: ""), systemImage: "trash")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .foregroundColor(.red)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                    } else if isParticipant {
                        Button(action: unjoinRun) {
                            Text(NSLocalizedString("Leave Run", comment: ""))
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .foregroundColor(.red)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .alert(NSLocalizedString("Delete Run", comment: "Alert title for run deletion"), isPresented: $showingDeleteAlert) {
            Button(NSLocalizedString("Cancel", comment: ""), role: .cancel) { }
            Button(NSLocalizedString("Delete", comment: ""), role: .destructive) { deleteRun() }
        } message: {
            Text(NSLocalizedString("Are you sure you want to delete this run? This action cannot be undone.", comment: "Alert message for run deletion confirmation"))
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
                Label(NSLocalizedString("Edit Run", comment: ""), systemImage: "pencil")
            }
            Button(role: .destructive, action: { showingDeleteAlert = true }) {
                Label(NSLocalizedString("Delete Run", comment: ""), systemImage: "trash")
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
                let userName = data["userName"] as? String ?? ""
                let userImage = data["userImage"] as? String ?? ""
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
                alertMessage = NSLocalizedString("Error updating join request status: ", comment: "") + error.localizedDescription
                showingAlert = true
                return
            }
            
            // Add the user to the currentParticipants array
            runRef.updateData([
                "currentParticipants": FieldValue.arrayUnion([joinRequest.userId])
            ]) { error in
                isLoading = false
                if let error = error {
                    alertMessage = NSLocalizedString("Error adding user to participants: ", comment: "") + error.localizedDescription
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
        let runRef = db.collection("runs").document(run.id)
        let joinRequestRef = runRef.collection("joinRequests").document(userId)
        
        // Remove the user from the participants array
        runRef.updateData([
            "currentParticipants": FieldValue.arrayRemove([userId])
        ]) { error in
            if let error = error {
                self.isLoading = false
                self.alertMessage = NSLocalizedString("Error leaving run: ", comment: "") + error.localizedDescription
                self.showingAlert = true
                return
            }
            
            // Delete the user's join request
            joinRequestRef.delete { error in
                self.isLoading = false
                if let error = error {
                    self.alertMessage = NSLocalizedString("Error removing join request: ", comment: "") + error.localizedDescription
                    self.showingAlert = true
                } else {
                    // Navigate back after successfully leaving and deleting the join request
                    self.presentationMode.wrappedValue.dismiss()
                }
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
                alertMessage = NSLocalizedString("Error deleting run: ", comment: "") + error.localizedDescription
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
                Text(NSLocalizedString("Requested ", comment: "Time indicator prefix") + user.timestamp.timeAgo())
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

// Add this helper view for consistent detail rows
struct DetailRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            Text(text)
                .font(.body)
        }
    }
}
