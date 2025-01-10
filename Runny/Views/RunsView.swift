import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RunsView: View {
    @State private var createdRuns: [Run] = []
    @State private var joinedRuns: [Run] = []
    @State private var allRuns: [Run] = []
    @State private var selectedSegment = 0
    @State private var showingCreateRun = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Segment Control
                    Picker("Run Type", selection: $selectedSegment) {
                        Text("All").tag(0)
                        Text("Joined").tag(1)
                        Text("Created").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    // Runs List
                    VStack(spacing: 15) {
                        switch selectedSegment {
                        case 0: // All Runs
                            if allRuns.isEmpty {
                                EmptyStateView(
                                    message: "No runs available",
                                    systemImage: "figure.run.circle",
                                    description: "Be the first to create a run!"
                                )
                            } else {
                                ForEach(allRuns) { run in
                                    RunCardView(run: run)
                                        .padding(.horizontal)
                                }
                            }
                        case 1: // Joined Runs
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
                        case 2: // Created Runs
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
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Runs")
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
        
        // Fetch all runs
        db.collection("runs")
            .order(by: "time", descending: false) // Order by run time instead of timestamp
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching all runs: \(error.localizedDescription)")
                    return
                }
                guard let documents = querySnapshot?.documents else { return }
                allRuns = documents.map { Run(id: $0.documentID, data: $0.data()) }
            }
        
        // Fetch created runs
        db.collection("runs")
            .whereField("createdBy", isEqualTo: userId)
            .order(by: "time", descending: false)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching created runs: \(error.localizedDescription)")
                    return
                }
                guard let documents = querySnapshot?.documents else { return }
                createdRuns = documents.map { Run(id: $0.documentID, data: $0.data()) }
            }
        
        // Fetch joined runs
        db.collection("runs")
            .whereField("currentParticipants", arrayContains: userId)
            .order(by: "time", descending: false)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching joined runs: \(error.localizedDescription)")
                    return
                }
                guard let documents = querySnapshot?.documents else { return }
                joinedRuns = documents.map { Run(id: $0.documentID, data: $0.data()) }
                    .filter { $0.createdBy != userId } // Exclude runs created by the user
            }
    }
} 
