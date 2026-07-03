import SwiftUI

struct DashboardHeaderView: View {
    @State private var searchText = ""
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
//                Text("Overview of your retail operations")
//                    .font(.system(size: 15))
//                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Search Bar
//            HStack(spacing: 8) {
//                Image(systemName: "magnifyingglass")
//                    .foregroundColor(.secondary)
//                TextField("Search stores, products, managers...", text: $searchText)
//                    .font(.system(size: 15))
//            }
//            .padding(.horizontal, 16)
//            .padding(.vertical, 12)
//            .background(Color(uiColor: .systemGray6))
//            .clipShape(Capsule())
//            .frame(maxWidth: 350)
//
            Spacer(minLength: 12).frame(maxWidth: 24)
            
            // Notification Bell
//            ZStack(alignment: .topTrailing) {
//                Image(systemName: "bell.fill")
//                    .font(.system(size: 20))
//                    .foregroundColor(.primary)
//                
//                Circle()
//                    .fill(Color.red)
//                    .frame(width: 14, height: 14)
//                    .overlay(
//                        Text("2")
//                            .font(.system(size: 9, weight: .bold))
//                            .foregroundColor(.white)
//                    )
//                    .offset(x: 4, y: -4)
//            }
            
             Spacer(minLength: 8).frame(maxWidth: 20)
            
            // Avatar
            Circle()
                .fill(Color.orange)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("AM")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    DashboardHeaderView()
        .padding()
}
