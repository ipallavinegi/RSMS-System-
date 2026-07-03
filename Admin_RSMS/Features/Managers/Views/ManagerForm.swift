import SwiftUI

struct ManagerForm: View {
    var memberToEdit: Manager? = nil
    var onDismiss: () -> Void
    var onSave: (Manager) -> Void
    
    @ObservedObject private var dataManager = RSMSDataManager.shared
    
    @State private var fullName: String
    @State private var emailAddress: String
    @State private var selectedStore: String
    @State private var showingValidationAlert = false
    @State private var validationMessage = ""
    
    init(memberToEdit: Manager? = nil, onDismiss: @escaping () -> Void, onSave: @escaping (Manager) -> Void) {
        self.memberToEdit = memberToEdit
        self.onDismiss = onDismiss
        self.onSave = onSave
        
        _fullName = State(initialValue: memberToEdit?.name ?? "")
        _emailAddress = State(initialValue: memberToEdit?.email ?? "")
        _selectedStore = State(initialValue: memberToEdit?.location ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Main Section Card
                    VStack(alignment: .leading, spacing: 20) {
                        // Section header
                        HStack(spacing: 10) {
                            Image(systemName: "person.crop.rectangle")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color(red: 0.1, green: 0.2, blue: 0.4))
                                .frame(width: 32, height: 32)
                                .background(Color(red: 0.1, green: 0.2, blue: 0.4).opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Text("Member Information")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                        }
                        
                        // Content
                        VStack(spacing: 20) {
                            // Name and Email row
                            HStack(alignment: .top, spacing: 16) {
                                inputField(label: "Full Name", placeholder: "e.g. Julian Drake", icon: "person.text.rectangle", text: $fullName)
                                inputField(label: "Email Address", placeholder: "julian@rsms-retail.com", icon: "envelope", text: $emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                            }
                            
                            // Store row
                            HStack(alignment: .top, spacing: 16) {
                                storeAssignmentField
                            }
                        }
                    }
                    .padding(24)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    // Onboarding Invitation Note
                    onboardingNote
                }
                .padding(28)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(memberToEdit == nil ? "Add Manager" : "Edit Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveManager) {
                        Text(memberToEdit == nil ? "Create" : "Update")
                            .fontWeight(.bold)
                    }
                }
            }
            .alert(isPresented: $showingValidationAlert) {
                Alert(
                    title: Text("Missing Information"),
                    message: Text(validationMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func saveManager() {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if trimmedName.isEmpty {
            validationMessage = "Please enter the manager's full name."
            showingValidationAlert = true
            return
        }
        
        if trimmedEmail.isEmpty || !trimmedEmail.hasSuffix("@gmail.com") {
            validationMessage = "Please enter a valid Gmail address (must end with @gmail.com)."
            showingValidationAlert = true
            return
        }
        
        if selectedStore.isEmpty {
            validationMessage = "Please select a store to assign the manager to."
            showingValidationAlert = true
            return
        }
        
        let initials = trimmedName.split(separator: " ").compactMap { $0.first }.map { String($0) }.joined()
        
        let member = Manager(
            id: memberToEdit?.id ?? UUID(),
            name: trimmedName,
            email: trimmedEmail,
            role: "Manager",  // Hardcoded to Manager as required
            location: selectedStore,
            shift: memberToEdit?.shift ?? "New Hire",
            imageName: memberToEdit?.imageName,
            initials: initials.isEmpty ? "?" : initials
        )
        onSave(member)
    }
        
    private var roleSelectionField: some View {
        EmptyView()
    }
        
    private func inputField(label: String, placeholder: String, icon: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                
                TextField(placeholder, text: text)
                    .font(.system(size: 15))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color(uiColor: .systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity)
    }
        
    private var storeAssignmentField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("STORE ASSIGNMENT")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            
            let activeStores = dataManager.stores.filter { !$0.isArchived }
            
            if activeStores.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "storefront")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Text("No stores available")
                        .foregroundColor(.secondary)
                        .font(.system(size: 15))
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(Color(uiColor: .systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
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
                    HStack(spacing: 8) {
                        Image(systemName: "storefront")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        if selectedStore.isEmpty {
                            Text("Select a store...")
                                .foregroundColor(.secondary)
                        } else {
                            Text(selectedStore)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background(Color(uiColor: .systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
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
}

#Preview {
    ManagerForm(
        onDismiss: {},
        onSave: { _ in }
    )
}
