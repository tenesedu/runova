import FirebaseFirestore
import FirebaseStorage
import UIKit

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

final class UserService {
    static let shared = UserService()
    private init() {}
    
    func saveUserData(userId: String, data: [String: Any], completion: @escaping (Error?) -> Void) {
        Firestore.firestore().collection("users").document(userId).setData(data, merge: true) { error in
            completion(error)
        }
    }
    
    func uploadProfileImage(image: UIImage, userId: String, completion: @escaping (String?, Error?) -> Void) {
        guard !userId.isEmpty else {
            completion(nil, NSError(domain: "AppError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"]))
            return
        }
        
        let resizedImage = image.resized(to: CGSize(width: 1024, height: 1024))
        
        guard let imageData = resizedImage?.jpegData(compressionQuality: 0.8) else {
            completion(nil, NSError(domain: "AppError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"]))
            return
        }
        
        let storageRef = Storage.storage().reference().child("users/\(userId)/profileImages/profile.jpg")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
              
                completion(nil, error)
                return
            }
            
            storageRef.downloadURL { url, error in
                DispatchQueue.main.async {
                    completion(url?.absoluteString, error)
                }
             
            }
        }
    }
    
    func checkUsernameAvailability(_ username: String) async -> Bool {
        do {
            let db = Firestore.firestore()
            let snapshot = try await db.collection("users")
                .whereField("username", isEqualTo: username)
                .getDocuments()
            return snapshot.documents.isEmpty
        } catch {
            print("Error checking username availability: \(error)")
            return false
        }
    }
}
