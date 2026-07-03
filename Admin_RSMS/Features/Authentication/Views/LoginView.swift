import SwiftUI

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    
    @State private var username = ""
    @State private var password = ""
    
    @State private var showVerification = false
    @State private var verificationCode = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    VStack(spacing: 8) {
                        Text("RSMS Admin")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                        
                        Text(showVerification ? "Verify your login" : "Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)
                    
                    VStack(spacing: 16) {
                        if !showVerification {
                            TextField("Username", text: $username)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                            
                            SecureField("Password", text: $password)
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                        } else {
                            TextField("6-Digit OTP Code", text: $verificationCode)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .font(.system(size: 24, weight: .medium, design: .monospaced))
                                .multilineTextAlignment(.center)
                        }
                        
                        if let error = authManager.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: handleAction) {
                            HStack {
                                Spacer()
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(showVerification ? "Verify Code" : "Sign In")
                                        .font(.headline)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(authManager.isLoading || (showVerification ? verificationCode.isEmpty : (username.isEmpty || password.isEmpty)))
                        .padding(.top, 8)
                        
                        if showVerification {
                            Button(action: { 
                                showVerification = false
                                authManager.signOut()
                            }) {
                                Text("Back to Sign In")
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(24)
                    .background(Color(uiColor: .systemBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
                    .padding(.horizontal, 24)
                }
            }
        }
    }
    
    private func handleAction() {
        Task {
            if showVerification {
                let success = await authManager.verifyCustomOTP(code: verificationCode)
                if success {
                    // Success! App routes to ContentView automatically.
                }
            } else {
                let success = await authManager.signIn(username: username, password: password)
                if success {
                    // Credentials verified + OTP sent — show verification screen
                    withAnimation {
                        showVerification = true
                    }
                }
            }
        }
    }
}
