// import SwiftUI
// import FirebaseFirestore
// import FirebaseAuth

// struct ConnectionsView: View {
//     @State private var connections: [Runner] = []
//     @State private var isLoading = true
    
//     var body: some View {
//         List(connections) { connection in
//             NavigationLink(destination: RunnerDetailView(runner: connection)) {
//                 HStack {
//                     // Profile Image
//                     AsyncImage(url: URL(string: connection.profileImageUrl)) { image in
//                         image
//                             .resizable()
//                             .scaledToFill()
//                             .frame(width: 50, height: 50)
//                             .clipShape(Circle())
//                     } placeholder: {
//                         Circle()
//                             .fill(Color.gray.opacity(0.2))
//                             .frame(width: 50, height: 50)
//                             .overlay(Text("👤").font(.system(size: 25)))
//                     }
                    
//                     VStack(alignment: .leading) {
//                         Text(connection.name)
//                             .font(.headline)
//                         Text(connection.city)
//                             .font(.subheadline)
//                             .foregroundColor(.gray)
//                     }
//                 }
//             }
//         }
//         .navigationTitle("My Connections")
//         .onAppear {
//             fetchConnections()
//         }
//     }
    
//     private func fetchConnections() {
//         guard let userId = Auth.auth().currentUser?.uid else { return }
        
//         // Clear existing connections before fetching
//         connections.removeAll()
        
//         let db = Firestore.firestore()
//         db.collection("users").document(userId).getDocument { snapshot, error in
//             guard let document = snapshot,
//                   let connectionIds = document.data()?["connections"] as? [String] else {
//                 isLoading = false
//                 return
//             }
            
//             // Fetch each connection's details
//             for connectionId in connectionIds {
//                 db.collection("users").document(connectionId).getDocument { snapshot, error in
//                     if let document = snapshot,
//                        let data = document.data() {
//                         let runner = Runner(
//                             id: document.documentID,
//                             name: data["name"] as? String ?? "Unknown",
//                             age: data["age"] as? String ?? "N/A",
//                             averagePace: data["averagePace"] as? String ?? "N/A",
//                             city: data["city"] as? String ?? "Unknown",
//                             profileImageUrl: data["profileImageUrl"] as? String ?? "",
//                             gender: data["gender"] as? String ?? "Not specified"
//                         )
                        
//                         DispatchQueue.main.async {
//                             connections.append(runner)
//                         }
//                     }
//                 }
//             }
            
//             isLoading = false
//         }
//     }
// } 