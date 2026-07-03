import SwiftUI

struct StoreDetailModalView: View {
    let store: AdminStore
    var onDismiss: () -> Void
    
    @State private var employees: [User] = []
    @State private var isLoadingEmployees = true
    
    private let userService = UserService()
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Store Details")) {
                    ListRow(
                        label: "Store ID",
                        value: store.storeID ?? "Auto-generated",
                        icon: "number"
                    )
                    ListRow(
                        label: "Location / Address",
                        value: store.address,
                        icon: "mappin.circle.fill"
                    )
                    ListRow(
                        label: "Status",
                        value: store.status.rawValue.capitalized,
                        icon: "circle.fill",
                        valueColor: statusColor(for: store.status)
                    )
                }
                
                Section(header: Text("Assigned Manager")) {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color(uiColor: .systemGray5))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(store.managerInitials.isEmpty ? "--" : store.managerInitials)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.managerName.isEmpty ? "Unassigned" : store.managerName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            Text("Manager")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Employees")) {
                    if isLoadingEmployees {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else if employees.isEmpty {
                        Text("No employees assigned to this store.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(employees) { employee in
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color(uiColor: .systemGray5))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(employeeInitials(for: employee.fullName))
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.primary)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(employee.fullName)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text(employee.designation ?? "Employee")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle(store.name)
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
            await fetchEmployees()
        }
    }
    
    // MARK: - Helpers
    
    private func fetchEmployees() async {
        do {
            let fetchedUsers = try await userService.fetchUsersByStore(storeId: store.id)
            DispatchQueue.main.async {
                self.employees = fetchedUsers
                self.isLoadingEmployees = false
            }
        } catch {
            print("Error fetching employees: \(error)")
            DispatchQueue.main.async {
                self.isLoadingEmployees = false
            }
        }
    }
    
    private func statusColor(for status: StoreStatus) -> Color {
        switch status {
        case .active: return .green
        case .maintenance: return .orange
        case .inventory: return .blue
        }
    }
    
    private func employeeInitials(for name: String) -> String {
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
    var valueColor: Color = .primary
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
            
            Text(label)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }
}
