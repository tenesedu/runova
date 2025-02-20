import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAccountAlert = false
    @State private var showingLogoutAlert = false
    @State private var showingFeedbackForm = false
    @EnvironmentObject private var authState: AuthenticationState
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        List {
            Section {
                // // Account Settings
                // NavigationLink(destination: AccountSecurityView()) {
                //     SettingsRow(icon: "lock.fill", title: "Account Security", color: .blue)
                // }
                
                // // Notifications
                // NavigationLink(destination: NotificationSettingsView()) {
                //     SettingsRow(icon: "bell.fill", title: "Notifications", color: .red)
                // }
                
                // // Privacy Settings
                // NavigationLink(destination: PrivacySettingsView()) {
                //     SettingsRow(icon: "hand.raised.fill", title: "Privacy", color: .purple)
                // }
            } header: {
                Text("Account")
            }
            
            Section {
                // Feedback
                Button(action: { showingFeedbackForm = true }) {
                    SettingsRow(icon: "star.fill", title: "Send Feedback", color: .yellow)
                }
                
                // Help & Support
                Link(destination: URL(string: "https://runny.app/support")!) {
                    SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: .green)
                }
            } header: {
                Text("Support")
            }
            
            Section {
                // Terms & Conditions
                Link(destination: URL(string: "https://runny.app/terms")!) {
                    SettingsRow(icon: "doc.text.fill", title: "Terms & Conditions", color: .gray)
                }
                
                // Privacy Policy
                Link(destination: URL(string: "https://runny.app/privacy")!) {
                    SettingsRow(icon: "shield.fill", title: "Privacy Policy", color: .gray)
                }
                
                // // About
                // NavigationLink(destination: AboutView()) {
                //     SettingsRow(icon: "info.circle.fill", title: "About Runny", color: .gray)
                // }
            } header: {
                Text("Legal")
            }
            
            Section {
                // Logout
                Button(action: { showingLogoutAlert = true }) {
                    SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Log Out", color: .blue)
                }
                
                // Delete Account
                Button(action: { showingDeleteAccountAlert = true }) {
                    SettingsRow(icon: "trash.fill", title: "Delete Account", color: .red)
                }
            } footer: {
                Text("Version 1.0.0")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Profile")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .alert("Log Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        // .sheet(isPresented: $showingFeedbackForm) {
        //     FeedbackFormView()
        // }
    }

    private func logout() {
        // Stop location updates first
        locationManager.stopUpdatingLocation()
        
        // Use the existing handleLogout method
        authState.handleLogout()
    }
    
    private func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        
        // First stop all listeners and location updates
        locationManager.stopUpdatingLocation()
        authState.stopListening()
        
        // Show loading indicator or disable UI here
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Delete all user-related data
        let userRef = db.collection("users").document(user.uid)
        batch.deleteDocument(userRef)
        
        // Delete user's runs
        db.collection("runs")
            .whereField("createdBy", isEqualTo: user.uid)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    documents.forEach { doc in
                        batch.deleteDocument(doc.reference)
                    }
                }
                
                // Delete user's messages and conversations
                db.collection("conversations")
                    .whereField("participants", arrayContains: user.uid)
                    .getDocuments { snapshot, error in
                        if let documents = snapshot?.documents {
                            documents.forEach { doc in
                                batch.deleteDocument(doc.reference)
                            }
                            
                            // Commit all deletions
                            batch.commit { error in
                                if let error = error {
                                    print("Error deleting user data: \(error.localizedDescription)")
                                    return
                                }
                                
                                // After Firestore data is deleted, delete Auth account
                                user.delete { error in
                                    if let error = error {
                                        print("Error deleting account: \(error.localizedDescription)")
                                    } else {
                                        print("Account and all data deleted successfully")
                                        // Force sign out
                                        do {
                                            try Auth.auth().signOut()
                                            // Reset any cached data
                                            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
                                        } catch {
                                            print("Error signing out: \(error.localizedDescription)")
                                        }
                                    }
                                }
                            }
                        }
                    }
            }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 20))
                .frame(width: 24, height: 24)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}
