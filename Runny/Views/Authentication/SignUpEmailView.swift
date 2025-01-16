import SwiftUI
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class SignUpViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var errorMessage: String = ""
    @Published var isSignUpSuccessful: Bool = false

    func signUp() {

        guard !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        Task {
            do {
                let returnedUserData = try await AuthenticationManager.shared.createUser(email: email, password: password)
                
                // Set onboardingCompleted to false for new users
                let db = Firestore.firestore()
                try await db.collection("users").document(returnedUserData.uid).setData([
                    "email": email,
                    "onboardingCompleted": false,
                    "createdAt": FieldValue.serverTimestamp()
                ])
                
                isSignUpSuccessful = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}


struct SignUpView: View {
    @StateObject private var viewModel = SignUpViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("Create Account")
                    .font(.largeTitle)
                    .padding()

                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding()

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Button(action: viewModel.signUp) {
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
            .fullScreenCover(isPresented: $viewModel.isSignUpSuccessful) {
                OnboardingView()
            }
        }
    }
} 
