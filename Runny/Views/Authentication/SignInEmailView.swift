import SwiftUI
import FirebaseAuth

@MainActor
final class SignInEmailViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoginSuccessful: Bool = false
    @Published var showingSignUp: Bool = false

    func signIn() {
        Task {
            do {
                guard !email.isEmpty else {
                    errorMessage = "Email is required"
                    return
                }

                guard !password.isEmpty else {
                    errorMessage = "Password is required"
                    return
                }

                let authDataResult = try await AuthenticationManager.shared.signIn(email: email, password: password)
                print("User signed in: \(authDataResult.uid)")
                isLoginSuccessful = true
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct SignInEmailView: View {
    @StateObject private var viewModel = SignInEmailViewModel()
    @State private var showingSignUp: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to Runny")
                    .font(.largeTitle)
                    .padding()

                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding()

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Button(action: {
                    viewModel.signIn()
                }) {
                    Text("Login")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding()

                HStack {
                    Text("Don't have an account?")
                    Button(action: {
                        showingSignUp = true
                    }) {
                        Text("Sign Up")
                            .foregroundColor(.blue)
                            .fontWeight(.bold)
                    }
                }
                .padding()

                Spacer()
            }
            .padding()
            .navigationTitle("Login")
            .fullScreenCover(isPresented: $viewModel.isLoginSuccessful) {
                HomeView(selectedTab: .constant(0), selectedSegment: .constant(0))
            }
            .sheet(isPresented: $viewModel.showingSignUp) {
                SignUpView()
            }
        }
    }
} 
