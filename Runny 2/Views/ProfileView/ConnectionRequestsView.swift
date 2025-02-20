import SwiftUI
import FirebaseFirestore

struct ConnectionRequestsView: View {
    @StateObject private var connectionManager = ConnectionManager()
    
    var body: some View {
        VStack {
            if connectionManager.receivedRequests.isEmpty {
                EmptyStateView(
                    message: "No Pending Requests",
                    systemImage: "person.badge.plus",
                    description: "You don't have any connection requests at the moment."
                )
            } else {
                List(connectionManager.receivedRequests) { request in
                    PendingRequestRow(request: request)
                }
            }
        }
        .navigationTitle("Connection Requests")
        .onAppear {
            connectionManager.fetchAllRequests()
        }
    }
}

struct ConnectionRequestRow_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ConnectionRequestsView()
        }
    }
}
