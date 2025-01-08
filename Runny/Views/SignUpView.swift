import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String = ""
    @State private var isSignUpSuccessful: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Create Account")
                    .font(.largeTitle)
                    .padding()

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding()

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Button(action: signUp) {
                    Text("Sign Up")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()

                Spacer()
            }
            .padding()
            .navigationTitle("Sign Up")
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .fullScreenCover(isPresented: $isSignUpSuccessful) {
                HomeView()
            }
        }
    }

    private func signUp() {
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let userId = result?.user.uid {
                let db = Firestore.firestore()
                let userData = [
                    "email": email,
                    "name": email.components(separatedBy: "@").first ?? "User",
                    "createdAt": FieldValue.serverTimestamp(),
                    "onboardingCompleted": false
                ]
                
                db.collection("users").document(userId).setData(userData) { error in
                    if let error = error {
                        print("Error creating user document: \(error.localizedDescription)")
                    } else {
                        isSignUpSuccessful = true
                    }
                }
            }
        }
    }
} 