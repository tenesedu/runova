import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RunsView: View {
    @State private var createdRuns: [Run] = []
    @State private var joinedRuns: [Run] = []
    @State private var selectedSegment = 0
    @State private var showingCreateRun = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Segment Control
                    Picker("Run Type", selection: $selectedSegment) {
                        Text("Joined").tag(0)
                        Text("Created").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    // Runs List
                    VStack(spacing: 15) {
                        if selectedSegment == 0 {
                            if joinedRuns.isEmpty {
                                EmptyStateView(
                                    message: "You haven't joined any runs yet",
                                    systemImage: "figure.run.circle"
                                )
                            } else {
                                ForEach(joinedRuns) { run in
                                    RunCardView(run: run)
                                        .padding(.horizontal)
                                }
                            }
                        } else {
                            if createdRuns.isEmpty {
                                EmptyStateView(
                                    message: "You haven't created any runs yet",
                                    systemImage: "figure.run.circle"
                                )
                            } else {
                                ForEach(createdRuns) { run in
                                    RunCardView(run: run)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("My Runs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateRun = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingCreateRun) {
                CreateView()
            }
            .onAppear {
                fetchRuns()
            }
        }
    }
    
    private func fetchRuns() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Fetch created runs
        db.collection("runs")
            .whereField("createdBy", isEqualTo: userId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                createdRuns = documents.map { Run(id: $0.documentID, data: $0.data()) }
            }
        
        // Fetch joined runs
        db.collection("runs")
            .whereField("currentParticipants", arrayContains: userId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else { return }
                joinedRuns = documents.map { Run(id: $0.documentID, data: $0.data()) }
                    .filter { $0.createdBy != userId } // Exclude runs created by the user
            }
    }
} 
