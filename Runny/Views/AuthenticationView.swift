import SwiftUI

struct AuthenticationView: View {
    @State private var showingLogin = false
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to Runny")
                    .font(.largeTitle)
                    .padding()
                
                Button(action: {
                    showingSignUp = true
                }) {
                    Text("Create Account")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                
                Button(action: {
                    showingLogin = true
                }) {
                    Text("Login")
                        .foregroundColor(.blue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
            }
            .padding()
            .fullScreenCover(isPresented: $showingSignUp) {
                SignUpView()
            }
            .fullScreenCover(isPresented: $showingLogin) {
                LoginView()
            }
        }
    }
} 
