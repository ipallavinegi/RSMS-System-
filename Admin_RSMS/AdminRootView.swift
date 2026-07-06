import SwiftUI

public struct AdminRootView: View {
    @StateObject private var dataManager = RSMSDataManager.shared
    @StateObject private var authManager = AuthManager.shared
    var onBackToPortal: () -> Void
    
    public init(onBackToPortal: @escaping () -> Void) {
        self.onBackToPortal = onBackToPortal
    }
    
    public var body: some View {
        Group {
            if authManager.isAuthenticated {
                ContentView()
                    .environmentObject(dataManager)
            } else {
                ZStack(alignment: .topLeading) {
                    LoginView()
                    
                    Button(action: onBackToPortal) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("Portal")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(uiColor: .systemBackground).opacity(0.8))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 60)
                }
            }
        }
    }
}
