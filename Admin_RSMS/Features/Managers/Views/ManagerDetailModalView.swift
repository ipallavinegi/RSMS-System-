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
            ScrollView {
                if sizeClass == .regular {
                    wideLayout
                } else {
                    compactLayout
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(manager.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onDismiss)
                }
            }
        }
        .task {
            await fetchUserProfile()
        }
    }
    
    // MARK: - Layouts
    
    private var wideLayout: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(spacing: 20) {
                overviewSection
            }
            .frame(maxWidth: .infinity)
            
            VStack(spacing: 20) {
                extendedDetailsSection
            }
            .frame(maxWidth: .infinity)
        }
        .padding(28)
    }
    
    private var compactLayout: some View {
        VStack(spacing: 20) {
            overviewSection
            extendedDetailsSection
        }
        .padding(20)
    }
    
    // MARK: - Sections
    
    private var overviewSection: some View {
        FormSectionCard(title: "Overview", icon: "person.crop.rectangle") {
            VStack(alignment: .leading, spacing: 16) {
                detailRow(label: "Store Assigned", value: manager.location, icon: "building.2.fill")
                detailRow(label: "Email Address", value: manager.email, icon: "envelope.fill")
            }
        }
    }
    
    private var extendedDetailsSection: some View {
        FormSectionCard(title: "Additional Details", icon: "list.bullet.clipboard") {
            if isLoadingProfile {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    detailRow(
                        label: "Phone Number",
                        value: userProfile?.phone?.isEmpty == false ? (userProfile?.phone ?? "Not Provided") : "Not Provided",
                        icon: "phone.fill"
                    )
                    
                    detailRow(
                        label: "Gender",
                        value: userProfile?.gender?.isEmpty == false ? (userProfile?.gender ?? "Not Provided") : "Not Provided",
                        icon: "person.fill.viewfinder"
                    )
                    
                    detailRow(
                        label: "Date of Birth",
                        value: userProfile?.dateOfBirth?.isEmpty == false ? (userProfile?.dateOfBirth ?? "Not Provided") : "Not Provided",
                        icon: "calendar"
                    )
                    
                    detailRow(
                        label: "Address",
                        value: userProfile?.address?.isEmpty == false ? (userProfile?.address ?? "Not Provided") : "Not Provided",
                        icon: "mappin.circle.fill"
                    )
                }
            }
        }
    }
    
    // MARK: - Helpers
    
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
    
    private func detailRow(label: String, value: String, icon: String, valueColor: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(valueColor)
            }
        }
    }
}
