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
    @StateObject private var authState = AuthenticationState()
    
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
    @Published var hasCompletedOnboarding = true  // Default to true for existing users
    private var handler: AuthStateDidChangeListenerHandle?
    
    func listen() {
        handler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if let userId = user?.uid {
                // User is logged in
                self?.isAuthenticated = true
                
                // Only check onboarding status for new users (those who just signed up)
                let db = Firestore.firestore()
                db.collection("users").document(userId).getDocument { document, _ in
                    if let document = document,
                       let onboardingCompleted = document.data()?["onboardingCompleted"] as? Bool {
                        self?.hasCompletedOnboarding = onboardingCompleted
                    } else {
                        // If the field doesn't exist, assume the user has completed onboarding
                        self?.hasCompletedOnboarding = true
                    }
                }
            } else {
                // User is logged out
                self?.isAuthenticated = false
                self?.hasCompletedOnboarding = true
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
