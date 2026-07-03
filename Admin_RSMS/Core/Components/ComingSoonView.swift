import SwiftUI

struct ComingSoonView: View {
    let title: String
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                        .opacity(0.3)
                    
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.system(size: 60, weight: .thin))
                        .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                
                VStack(spacing: 8) {
                    Text("\(title) Coming Soon")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    
                    Text("We're currently perfecting the \(title.lowercased()) experience. Stay tuned for a smarter way to manage your network.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 400)
                }
                
                Button(action: {}) {
                    Text("Notify Me")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.top, 20)
            }
            .padding()
        }
    }
}

#Preview {
    ComingSoonView(title: "Dashboard")
}
