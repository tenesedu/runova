import SwiftUI
import FirebaseFirestore

struct ExploreView: View {
    @State private var runs: [Run] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Runs Section
                    VStack(alignment: .leading) {
                        Text("Available Runs")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)
                        
                        if runs.isEmpty {
                            Text("No runs available")
                                .foregroundColor(.gray)
                                .padding()
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 15) {
                                    ForEach(runs) { run in
                                        RunCardView(run: run)
                                            .frame(width: 300)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Explore")
            .onAppear {
                fetchRuns()
            }
        }
    }
    
    private func fetchRuns() {
        let db = Firestore.firestore()
        db.collection("runs")
            .order(by: "time", descending: false)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching runs: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                runs = documents.map { Run(id: $0.documentID, data: $0.data()) }
            }
    }
} 
