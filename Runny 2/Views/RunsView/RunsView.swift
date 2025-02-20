import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct RunsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = RunsViewModel()
    @StateObject private var runViewModel = RunViewModel()
    
    @Binding var selectedSegment: Int
    @Binding var selectedTab: Int
    
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
                        TextField(NSLocalizedString("Search runs...", comment: ""), text: $vm.searchText)
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
                    Picker("Run Type", selection: $selectedSegment) {
                        Text(NSLocalizedString("All", comment: "Run filter option")).tag(0)
                        Text(NSLocalizedString("Joined", comment: "Run filter option")).tag(1)
                        Text(NSLocalizedString("Created", comment: "Run filter option")).tag(2)

                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    // Runs List
                    VStack(spacing: 15) {
                        switch selectedSegment {
                        case 0: // All Runs
                            if filteredAllRuns.isEmpty {
                                EmptyStateView(
                                    message: vm.searchText.isEmpty ? NSLocalizedString("No runs available", comment: "No runs available message"): NSLocalizedString("No results found", comment: ""),
                                    systemImage: "figure.run.circle",
                                    description: vm.searchText.isEmpty ? NSLocalizedString("Be the first to create a run!", comment: "" ) : NSLocalizedString("Try adjusting your search", comment: "")
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
                                    message: vm.searchText.isEmpty ? NSLocalizedString("You haven't joined any runs yet", comment: "") : NSLocalizedString("No results found", comment: ""),
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
                                    message: vm.searchText.isEmpty ? NSLocalizedString("You haven't created any runs yet", comment: "") : NSLocalizedString("No results found", comment: ""),
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

            }) {
                CreateRunView(selectedSegment: $selectedSegment, selectedTab: $selectedTab)
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
