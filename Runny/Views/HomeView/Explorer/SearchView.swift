//
//  SearchView.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 29/1/25.
//

import SwiftUI

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedScope: SearchScope = .all
    @State private var runners: [Runner] = []
    @State private var runs: [Run] = []
    @State private var communities: [Interest] = []
    
    enum SearchScope: String, CaseIterable {
        case all = "All"
        case runners = "Runners"
        case runs = "Runs"
        case communities = "Communities"
    }
    
    // Add computed properties for filtered results
    private var filteredRunners: [Runner] {
        if searchText.isEmpty {
            return runners
        }
        return runners.filter { runner in
            runner.name.localizedCaseInsensitiveContains(searchText) ||
            runner.city.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredRuns: [Run] {
        if searchText.isEmpty {
            return runs
        }
        return runs.filter { run in
            run.name.localizedCaseInsensitiveContains(searchText) ||
            run.location.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredCommunities: [Interest] {
        if searchText.isEmpty {
            return communities
        }
        return communities.filter { community in
            community.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField(NSLocalizedString("Search...", comment: ""), text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Scope Picker
                Picker("Search Scope", selection: $selectedScope) {
                    ForEach(SearchScope.allCases, id: \.self) { scope in
                        Text(NSLocalizedString(scope.rawValue, comment: "")).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        searchResults
                    }
                }
            }
            .navigationTitle(NSLocalizedString("Search", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private var searchResults: some View {
        switch selectedScope {
        case .all:
            VStack(spacing: 16) {
                if !filteredRunners.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Runners")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(filteredRunners) { runner in
                            RunnerSearchRow(runner: runner)
                        }
                    }
                }
                
                if !filteredRuns.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Runs")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(filteredRuns) { run in
                            RunSearchRow(run: run)
                        }
                    }
                }
                
                if !filteredCommunities.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Communities")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(filteredCommunities) { community in
                            CommunitySearchRow(community: community)
                        }
                    }
                }
                
                if filteredRunners.isEmpty && filteredRuns.isEmpty && filteredCommunities.isEmpty {
                    Text("No results found")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .padding(.vertical)
            
        case .runners:
            if filteredRunners.isEmpty {
                Text("No runners found")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(filteredRunners) { runner in
                    RunnerSearchRow(runner: runner)
                }
            }
            
        case .runs:
            if filteredRuns.isEmpty {
                Text("No runs found")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(filteredRuns) { run in
                    RunSearchRow(run: run)
                }
            }
            
        case .communities:
            if filteredCommunities.isEmpty {
                Text("No communities found")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(filteredCommunities) { community in
                    CommunitySearchRow(community: community)
                }
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let backgroundColor: Color
    var isOutlined: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(isOutlined ? .black : .white)
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isOutlined ? .black : .white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isOutlined ? backgroundColor : backgroundColor)
        )
        
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4)
    }
}

