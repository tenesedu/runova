import FirebaseFirestore
import FirebaseStorage

final class UserService {
    static let shared = UserService()
    private init() {}

    func saveUserData(userId: String, data: [String: Any], completion: @escaping (Error?) -> Void) {
        Firestore.firestore().collection("users").document(userId).setData(data, merge: true) { error in
            completion(error)
        }
    }

    func uploadProfileImage(_ image: UIImage, userId: String, completion: @escaping (String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }

        let storageRef = Storage.storage().reference().child("profile_images/\(userId).jpg")
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }

            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                completion(url?.absoluteString)
            }
        }
    }
}