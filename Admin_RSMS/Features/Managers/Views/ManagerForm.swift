import SwiftUI

struct ManagerForm: View {
    var memberToEdit: Manager? = nil
    var onDismiss: () -> Void
    var onSave: (Manager) -> Void
    
    @ObservedObject private var dataManager = RSMSDataManager.shared
    
    @State private var fullName: String
    @State private var emailAddress: String
    @State private var selectedRole: String
    @State private var selectedStore: String
    
    init(memberToEdit: Manager? = nil, onDismiss: @escaping () -> Void, onSave: @escaping (Manager) -> Void) {
        self.memberToEdit = memberToEdit
        self.onDismiss = onDismiss
        self.onSave = onSave
        
        _fullName = State(initialValue: memberToEdit?.name ?? "")
        _emailAddress = State(initialValue: memberToEdit?.email ?? "")
        _selectedRole = State(initialValue: memberToEdit?.role ?? "Manager")
        _selectedStore = State(initialValue: memberToEdit?.location ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Back Button
                    Button(action: onDismiss) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back to Manager List")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                    }
                    .padding(.top, 24)
                    
                    // Main Card
                    VStack(alignment: .leading, spacing: 0) {
                        // Card Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Member Information")
                                .font(.system(size: 20, weight: .bold))
                            Text("Configure identity and access levels for the new user account.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(24)
                        
                        Divider()
                        
                        // Card Content
                        VStack(alignment: .leading, spacing: 24) {
                            // Name and Email row
                            HStack(spacing: 24) {
                                inputField(label: "Full Name", placeholder: "e.g. Julian Drake", text: $fullName)
                                inputField(label: "Email Address", placeholder: "julian@rsms-retail.com", text: $emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                            }
                            
                            // Role and Store row
                            HStack(spacing: 24) {
                                inputField(label: "Role Selection", placeholder: "e.g. Manager", text: $selectedRole)
                                storeAssignmentField
                            }
                            
                            // Action Buttons
                            HStack {
                                Spacer()
                                Button(action: onDismiss) {
                                    Text("Cancel")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                }
                                .padding(.trailing, 24)
                                
                                Button(action: {
                                    if !fullName.isEmpty && !selectedRole.isEmpty {
                                        let initials = fullName.split(separator: " ").compactMap { $0.first }.map { String($0) }.joined()
                                        
                                        let member = Manager(
                                            id: memberToEdit?.id ?? UUID(),
                                            name: fullName,
                                            email: emailAddress,
                                            role: selectedRole,
                                            location: selectedStore.isEmpty ? "Assigned Store" : selectedStore,
                                            shift: memberToEdit?.shift ?? "New Hire",
                                            imageName: memberToEdit?.imageName,
                                            initials: initials.isEmpty ? "?" : initials
                                        )
                                        onSave(member)
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: memberToEdit == nil ? "person.badge.plus" : "pencil.circle")
                                        Text(memberToEdit == nil ? "Add Member" : "Save Changes")
                                    }
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(fullName.isEmpty || selectedRole.isEmpty ? Color.gray : Color(red: 0.1, green: 0.2, blue: 0.4))
                                    .cornerRadius(10)
                                }
                                .disabled(fullName.isEmpty || selectedRole.isEmpty)
                            }
                            .padding(.top, 8)
                        }
                        .padding(24)
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                    
                    // Onboarding Invitation Note
                    onboardingNote
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            
            // Status Bar (matching previous screens)
            statusBar
        }
        .navigationBarHidden(true)
    }
    
    private var headerView: some View {
        HStack(spacing: 24) {
            Text("Global Manager")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                Text("Search resources...")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(10)
            .frame(maxWidth: 350)
            
            Spacer()
            
            // Icons
            HStack(spacing: 12) {
                Button(action: {}) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Circle().fill(Color(uiColor: .secondarySystemGroupedBackground)))
                        
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: -2, y: 2)
                    }
                }
                
                Button(action: {}) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Circle().fill(Color(uiColor: .secondarySystemGroupedBackground)))
                }
                
                Button(action: {}) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    private func inputField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
            
            TextField(placeholder, text: text)
                .padding()
                .background(Color(uiColor: .systemGray6).opacity(0.5))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity)
    }
    
    private var storeAssignmentField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Store Assignment")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
            
            let activeStores = dataManager.stores.filter { !$0.isArchived }
            
            if activeStores.isEmpty {
                HStack {
                    Image(systemName: "storefront")
                        .foregroundColor(.secondary)
                    Text("No stores created yet")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    Spacer()
                }
                .padding()
                .background(Color(uiColor: .systemGray6).opacity(0.5))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
            } else {
                Menu {
                    Button(action: { selectedStore = "" }) {
                        Label("None", systemImage: selectedStore.isEmpty ? "checkmark" : "minus")
                    }
                    Divider()
                    ForEach(activeStores) { store in
                        Button(action: { selectedStore = store.name }) {
                            if selectedStore == store.name {
                                Label(store.name, systemImage: "checkmark")
                            } else {
                                Text(store.name)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "storefront")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                        if selectedStore.isEmpty {
                            Text("Select a store...")
                                .foregroundColor(.secondary)
                        } else {
                            Text(selectedStore)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(uiColor: .systemGray6).opacity(0.5))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    
    private var onboardingNote: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Onboarding Invitation")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                Text("An invitation email will be sent immediately after account creation with instructions to set their password and complete their profile.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4).opacity(0.8))
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var statusBar: some View {
        HStack(spacing: 24) {
            HStack(spacing: 8) {
                Circle().fill(Color.green).frame(width: 6, height: 6)
                Text("10 STORES ONLINE")
                    .font(.system(size: 9, weight: .bold))
            }
            
            HStack(spacing: 8) {
                Circle().fill(Color.orange).frame(width: 6, height: 6)
                Text("2 IN MAINTENANCE")
                    .font(.system(size: 9, weight: .bold))
            }
            
            Spacer()
            
            Text("SYNC STATUS: REAL-TIME • TODAY 09:42 AM")
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
        .background(Color.white)
        .overlay(Divider(), alignment: .top)
    }
}

#Preview {
    ManagerForm(
        onDismiss: {},
        onSave: { _ in }
    )
}
