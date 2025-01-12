import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RunsView: View {
    @State private var createdRuns: [Run] = []
    @State private var joinedRuns: [Run] = []
    @State private var allRuns: [Run] = []
    @State private var selectedSegment = 0
    @State private var showingCreateRun = false
    @State private var searchText = ""
    @State private var isRefreshing = false
    
    var filteredAllRuns: [Run] {
        if searchText.isEmpty {
            return allRuns
        }
        return allRuns.filter { run in
            run.name.localizedCaseInsensitiveContains(searchText) ||
            run.location.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredJoinedRuns: [Run] {
        if searchText.isEmpty {
            return joinedRuns
        }
        return joinedRuns.filter { run in
            run.name.localizedCaseInsensitiveContains(searchText) ||
            run.location.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var filteredCreatedRuns: [Run] {
        if searchText.isEmpty {
            return createdRuns
        }
        return createdRuns.filter { run in
            run.name.localizedCaseInsensitiveContains(searchText) ||
            run.location.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search runs...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    
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
                            if filteredAllRuns.isEmpty {
                                EmptyStateView(
                                    message: searchText.isEmpty ? "No runs available" : "No results found",
                                    systemImage: "figure.run.circle",
                                    description: searchText.isEmpty ? "Be the first to create a run!" : "Try adjusting your search"
                                )
                            } else {
                                ForEach(filteredAllRuns) { run in
                                    RunCardView(run: run)
                                        .padding(.horizontal, 16)
                                        .onTapGesture {
                                            print("Tapped run with ID: \(run.id)")
                                        }
                                }
                            }
                        case 1: // Joined Runs
                            if filteredJoinedRuns.isEmpty {
                                EmptyStateView(
                                    message: searchText.isEmpty ? "You haven't joined any runs yet" : "No results found",
                                    systemImage: "figure.run.circle"
                                )
                            } else {
                                ForEach(filteredJoinedRuns) { run in
                                    RunCardView(run: run)
                                        .padding(.horizontal, 16)
                                }
                            }
                        case 2: // Created Runs
                            if filteredCreatedRuns.isEmpty {
                                EmptyStateView(
                                    message: searchText.isEmpty ? "You haven't created any runs yet" : "No results found",
                                    systemImage: "figure.run.circle"
                                )
                            } else {
                                ForEach(filteredCreatedRuns) { run in
                                    RunCardView(run: run)
                                        .padding(.horizontal, 16)
                                }
                            }
                        default:
                            EmptyView()
                        }
                    }
                }
            }
            .refreshable {
                await refreshData()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Runs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateRun = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.black)
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
    
    private func refreshData() async {
        await MainActor.run {
            fetchRuns()
        }
    }
}

struct RefreshableScrollView<Content: View>: View {
    var action: () async -> Void
    var content: Content
    
    init(action: @escaping () async -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        if #available(iOS 15.0, *) {
            ScrollView {
                content
            }
            .refreshable {
                await action()
            }
        } else {
            ScrollView {
                content
            }
        }
    }
} 
