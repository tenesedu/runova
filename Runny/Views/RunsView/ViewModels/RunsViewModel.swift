//
//  RunsViewModel.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 27/1/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class RunsViewModel: ObservableObject {
    @Published var createdRuns: [Run] = []
    @Published var joinedRuns: [Run] = []
    @Published var allRuns: [Run] = []
    @Published var showingCreateRun = false
    @Published var searchText = ""
    @Published var isRefreshing = false
    
    func fetchRuns() {
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
                self.allRuns = documents.map { Run(id: $0.documentID, data: $0.data()) }
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
                self.createdRuns = documents.map { Run(id: $0.documentID, data: $0.data()) }
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
                self.joinedRuns = documents.map { Run(id: $0.documentID, data: $0.data()) }
                    .filter { $0.createdBy != userId } // Exclude runs created by the user
            }
    }
    
}
