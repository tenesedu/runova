//
//  OnboardingViewModel.swift
//  Runny
//
//  Created by Eduardo Tenes Trillo on 20/2/25.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Onboarding Data Model
struct OnboardingData {
    var name: String = ""
    var age: Int = 18
    var username: String = ""
    var profileImage: UIImage?
    var gender: String = ""
    var city: String = ""
    var goals: [String] = []
    var interests: [String] = []
    var locationEnabled: Bool = false
}

// MARK: - ViewModel
@MainActor
final class OnboardingViewModel: ObservableObject {
    
    @Published var onboardingData = OnboardingData()
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var isUploading: Bool = false
    
    func completeOnboarding(selectedImage: UIImage?) {
        guard let userId = Auth.auth().currentUser?.uid else {
            alertMessage = "No user ID found"
            showAlert = true
            return
        }
        
        isUploading = true
        
        if let selectedImage = selectedImage {
            UserService.shared.uploadProfileImage(image: selectedImage, userId: userId) { [weak self] imageUrl, error  in
                
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.isUploading = false
                    
                    if let error = error {
                        self.alertMessage = "Image upload failed: \(error.localizedDescription)"
                        self.showAlert = true
                        return
                    }
                    self.saveUserProfile(userId: userId, imageUrl: imageUrl)
                }
            }
        }else {
            
            DispatchQueue.main.async{
                self.isUploading = false
                self.saveUserProfile(userId: userId, imageUrl: nil)
            }
        }
    }

    
    private func saveUserProfile(userId: String, imageUrl: String?) {
        let userData: [String: Any] = [
            "name": onboardingData.name,
            "age": onboardingData.age,
            "username": onboardingData.username,
            "profileImageUrl": imageUrl ?? "",
            "gender": onboardingData.gender,
            "city": onboardingData.city,
            "goals": onboardingData.goals,
            "interests": onboardingData.interests,
            "locationEnabled": onboardingData.locationEnabled,
            "onboardingCompleted": onboardingData.locationEnabled,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        UserService.shared.saveUserData(userId: userId, data: userData) { [weak self] error in
            self?.isUploading = false
            
            if let error = error {
                self?.alertMessage = "Error saving user data: \(error.localizedDescription)"
                self?.showAlert = true
                return
            }
        }
    }
}
