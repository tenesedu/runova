//
//  ContentView.swift
//  Runny
//
//  Created by Joaquín Tenés on 7/1/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @EnvironmentObject private var authState: AuthenticationState
    
    var body: some View {
        Group {
            if authState.isAuthenticated {
                if authState.hasCompletedOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            } else {
                AuthenticationView()
            }
        }   
        .onAppear {
            
            authState.listen()
        }
    }
}

class AuthenticationState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasCompletedOnboarding = false
    private var handler: AuthStateDidChangeListenerHandle?
    private var userListener: ListenerRegistration?
    
    func stopListening() {
        handler = nil
        userListener?.remove()
        userListener = nil
        print("Stopped auth listeners")
    }
    
    func listen() {
        stopListening()
        
        handler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let userId = user?.uid {
                self?.isAuthenticated = true
                self?.setupUserListener(userId: userId)
            } else {
                self?.isAuthenticated = false
                self?.hasCompletedOnboarding = false
                self?.userListener?.remove()
                self?.userListener = nil
            }
        }
    }
    
    private func setupUserListener(userId: String) {
        let db = Firestore.firestore()
        userListener = db.collection("users").document(userId)
            .addSnapshotListener { [weak self] document, _ in
                if let document = document,
                   let onboardingCompleted = document.data()?["onboardingCompleted"] as? Bool {
                    self?.hasCompletedOnboarding = onboardingCompleted
                } else {
                    self?.hasCompletedOnboarding = false
                }
            }
    }
    
    deinit {
        handler = nil
        userListener?.remove()
    }
    
    func handleAccountDeletion() {
        print("Handling account deletion...")
        // First set state to trigger cleanup
        isAuthenticated = false
        hasCompletedOnboarding = true
        
        // Then stop listeners
        stopListening()
        
        // Clear user defaults
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }
    
    func handleLogout() {
        print("Handling logout...")
        do {
            // First set state to trigger cleanup
            isAuthenticated = false
            hasCompletedOnboarding = true
            
            // Then stop listeners
            stopListening()
            
            // Finally sign out
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
