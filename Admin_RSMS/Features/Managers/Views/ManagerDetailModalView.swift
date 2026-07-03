import SwiftUI

struct ManagerDetailModalView: View {
    let manager: Manager
    var onDismiss: () -> Void
    
    @State private var userProfile: User? = nil
    @State private var isLoadingProfile = true
    
    private let userService = UserService()
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color(uiColor: .systemGray5))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(managerInitials(for: manager.name))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primary)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(manager.name)
                                .font(.title3.weight(.bold))
                            Text(manager.role)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Overview")) {
                    ListRow(label: "Store Assigned", value: manager.location, icon: "building.2.fill")
                    ListRow(label: "Email Address", value: manager.email, icon: "envelope.fill")
                }
                
                Section(header: Text("Additional Details")) {
                    if isLoadingProfile {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else {
                        ListRow(
                            label: "Phone Number",
                            value: userProfile?.phone?.isEmpty == false ? (userProfile?.phone ?? "Not Provided") : "Not Provided",
                            icon: "phone.fill"
                        )
                        ListRow(
                            label: "Gender",
                            value: userProfile?.gender?.isEmpty == false ? (userProfile?.gender ?? "Not Provided") : "Not Provided",
                            icon: "person.fill.viewfinder"
                        )
                        ListRow(
                            label: "Date of Birth",
                            value: userProfile?.dateOfBirth?.isEmpty == false ? (userProfile?.dateOfBirth ?? "Not Provided") : "Not Provided",
                            icon: "calendar"
                        )
                        ListRow(
                            label: "Address",
                            value: userProfile?.address?.isEmpty == false ? (userProfile?.address ?? "Not Provided") : "Not Provided",
                            icon: "mappin.circle.fill"
                        )
                    }
                }
            }
            .navigationTitle("Manager Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        onDismiss()
                    }
                }
            }
        }
        .task {
            await fetchUserProfile()
        }
    }
    
    private func fetchUserProfile() async {
        do {
            let profile = try await userService.fetchUserByEmail(email: manager.email)
            DispatchQueue.main.async {
                self.userProfile = profile
                self.isLoadingProfile = false
            }
        } catch {
            print("Error fetching user profile: \(error)")
            DispatchQueue.main.async {
                self.isLoadingProfile = false
            }
        }
    }
    
    private func managerInitials(for name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components.last?.prefix(1) ?? ""
            return String(first + last).uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
}

fileprivate struct ListRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 4)
    }
}

