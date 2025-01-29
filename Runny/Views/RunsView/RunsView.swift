import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RunsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = RunsViewModel()
    @StateObject private var runViewModel = RunViewModel()
    
    
    var filteredAllRuns: [Run] {
        if vm.searchText.isEmpty {
            return vm.allRuns
        }
        return vm.allRuns.filter { run in
            run.name.localizedCaseInsensitiveContains(vm.searchText) ||
            run.location.localizedCaseInsensitiveContains(vm.searchText)
        }
    }
    
    var filteredJoinedRuns: [Run] {
        if vm.searchText.isEmpty {
            return vm.joinedRuns
        }
        return vm.joinedRuns.filter { run in
            run.name.localizedCaseInsensitiveContains(vm.searchText) ||
            run.location.localizedCaseInsensitiveContains(vm.searchText)
        }
    }
    
    var filteredCreatedRuns: [Run] {
        if vm.searchText.isEmpty {
            return vm.createdRuns
        }
        return vm.createdRuns.filter { run in
            run.name.localizedCaseInsensitiveContains(vm.searchText) ||
            run.location.localizedCaseInsensitiveContains(vm.searchText)
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
                        TextField("Search runs...", text: $vm.searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !vm.searchText.isEmpty {
                            Button(action: {
                                vm.searchText = ""
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
                    Picker("Run Type", selection: $vm.selectedSegment) {
                        Text("All").tag(0)
                        Text("Joined").tag(1)
                        Text("Created").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    // Runs List
                    VStack(spacing: 15) {
                        switch vm.selectedSegment {
                        case 0: // All Runs
                            if filteredAllRuns.isEmpty {
                                EmptyStateView(
                                    message: vm.searchText.isEmpty ? "No runs available" : "No results found",
                                    systemImage: "figure.run.circle",
                                    description: vm.searchText.isEmpty ? "Be the first to create a run!" : "Try adjusting your search"
                                )
                            } else {
                                ForEach(filteredAllRuns) { run in
                                    RunCardView(run: run, viewModel: runViewModel)
                                        .padding(.horizontal, 16)
                                }
                            }
                        case 1: // Joined Runs
                            if filteredJoinedRuns.isEmpty {
                                EmptyStateView(
                                    message: vm.searchText.isEmpty ? "You haven't joined any runs yet" : "No results found",
                                    systemImage: "figure.run.circle"
                                )
                            } else {
                                ForEach(filteredJoinedRuns) { run in
                                    RunCardView(run: run, viewModel: runViewModel)
                                        .padding(.horizontal, 16)
                                }
                            }
                        case 2: // Created Runs
                            if filteredCreatedRuns.isEmpty {
                                EmptyStateView(
                                    message: vm.searchText.isEmpty ? "You haven't created any runs yet" : "No results found",
                                    systemImage: "figure.run.circle"
                                )
                            } else {
                                ForEach(filteredCreatedRuns) { run in
                                    RunCardView(run: run, viewModel: runViewModel)
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
                        vm.showingCreateRun = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.black)
                    }
                }
            }
            .sheet(isPresented: $vm.showingCreateRun, onDismiss: {
                vm.selectedSegment = 2
            }) {
                CreateRunView(selectedSegment: $vm.selectedSegment)
            }
            .onAppear {
                vm.fetchRuns()
            }
        }
    }
    
    
    
    private func refreshData() async {
        await MainActor.run {
            vm.fetchRuns()
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
