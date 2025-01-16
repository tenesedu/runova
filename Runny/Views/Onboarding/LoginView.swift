import SwiftUI
import FirebaseAuth

final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoginSuccessful: Bool = false
    @Published var showingSignUp: Bool = false

    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                self.errorMessage = error.localizedDescription
                print("Login error: \(self.errorMessage)")
            } else {
                self.isLoginSuccessful = true
                print("Login successful!")
            }
        }
    }
}

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
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
                    viewModel.login()
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
                HomeView()
            }
            .sheet(isPresented: $viewModel.showingSignUp) {
                SignUpView()
            }
        }
    }
} 
