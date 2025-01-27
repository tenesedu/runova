import FirebaseFirestore

enum RunStatus: String, CaseIterable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case canceled = "Canceled"
    case finalized = "Finalized"
}

struct Run: Identifiable {
    let id: String
    let name: String
    let description: String
    let time: Date
    let location: String
    let maxParticipants: Int
    let currentParticipants: [String]
    let joinRequests: [String]
    let distance: Double
    let averagePace: String
    let terrain: String?
    let createdBy: String
    let createdAt: Date
    let title: String
    let status: RunStatus
    
    var isFull: Bool {
        return currentParticipants.count >= maxParticipants
    }
    
    init(id: String, data: [String: Any]) {
        guard !id.isEmpty else {
            fatalError("Run ID cannot be empty")
        }
        self.id = id
        self.name = data["name"] as? String ?? ""
        self.description = data["description"] as? String ?? ""
        self.time = (data["time"] as? Timestamp)?.dateValue() ?? Date()
        self.location = data["location"] as? String ?? ""
        self.maxParticipants = data["maxParticipants"] as? Int ?? 0
        self.currentParticipants = data["currentParticipants"] as? [String] ?? []
        self.joinRequests = data["joinRequests"] as? [String] ?? []
        self.distance = data["distance"] as? Double ?? 0.0
        self.averagePace = data["averagePace"] as? String ?? ""
        self.terrain = data["terrain"] as? String
        self.createdBy = data["createdBy"] as? String ?? ""
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.title = data["title"] as? String ?? ""
        self.status = RunStatus(rawValue: data["status"] as? String ?? "") ?? .pending
    }
    
   
    
    func fetchJoinRequests(completion: @escaping ([String]) -> Void) {
        let db = Firestore.firestore()
        db.collection("runs").document(id)
          .collection("joinRequests")
          .whereField("status", isEqualTo: "pending")
          .getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching join requests: \(error.localizedDescription)")
                completion([])
                return
            }
            
            let requests = snapshot?.documents.compactMap { $0.data()["userId"] as? String } ?? []
            completion(requests)
        }
    }
} 
