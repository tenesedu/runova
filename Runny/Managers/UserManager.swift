//
//  UserManager.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 9/3/25.
//

import FirebaseAuth
import Combine // Reactive
import FirebaseFirestore

class UserManager: ObservableObject {
    @Published var currentUser: UserApp?
    @Published var profileImageUrl: String?

    static let shared = UserManager()
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    private init() {
        listenToAuthChanges()
    }

    func listenToAuthChanges() {
        Auth.auth().addStateDidChangeListener { _, user in
            if let user = user {
                self.loadUserData(userId: user.uid)
            } else {
                self.currentUser = nil
                self.profileImageUrl = nil
            }
        }
    }

    func loadUserData(userId: String) {
        Firestore.firestore().collection("users").document(userId).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                DispatchQueue.main.async {
                    // Asegúrate de usar UserApp en lugar de User
                    self.currentUser = UserApp(id: userId, data: data)
                    self.profileImageUrl = data["profileImageUrl"] as? String
                }
            }
        }
    }
    func getUserData(by userId: String, completion: @escaping (UserApp?) -> Void) {
        Firestore.firestore().collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            if let data = snapshot?.data() {
                let user = UserApp(id: userId, data: data)
        
                DispatchQueue.main.async {
                    completion(user)
                }
            } else {
                print("User not found in Firestore.")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }


    func loadUserData(userId: String, completion: @escaping (UserApp?) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error loading user data: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let data = snapshot?.data() {
                let user = UserApp(id: snapshot?.documentID ?? "", data: data)
                completion(user)
            } else {
                completion(nil)
            }
        }
    }
}
