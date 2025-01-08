import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String = ""
    @State private var isLoginSuccessful: Bool = false
    @State private var showingSignUp: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to Runny")
                    .font(.largeTitle)
                    .padding()

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .padding()

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Button(action: {
                    login()
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
            .fullScreenCover(isPresented: $isLoginSuccessful) {
                HomeView()
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
    }

    private func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                print("Login error: \(errorMessage)")
            } else {
                isLoginSuccessful = true
                print("Login successful!")
            }
        }
    }
} 
