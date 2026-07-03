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
            ScrollView {
                if sizeClass == .regular {
                    wideLayout
                } else {
                    compactLayout
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(store.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onDismiss)
                }
            }
        }
        .task {
            await fetchEmployees()
        }
    }
    
    // MARK: - Layouts
    
    private var wideLayout: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(spacing: 20) {
                storeDetailsSection
            }
            .frame(maxWidth: .infinity)
            
            VStack(spacing: 20) {
                managerSection
                employeesSection
            }
            .frame(maxWidth: .infinity)
        }
        .padding(28)
    }
    
    private var compactLayout: some View {
        VStack(spacing: 20) {
            storeDetailsSection
            managerSection
            employeesSection
        }
        .padding(20)
    }
    
    // MARK: - Sections
    
    private var storeDetailsSection: some View {
        FormSectionCard(title: "Store Details", icon: "building.2") {
            VStack(alignment: .leading, spacing: 16) {
                detailRow(label: "Store ID", value: store.storeID ?? "Auto-generated", icon: "number")
                detailRow(label: "Location / Address", value: store.address, icon: "mappin.circle.fill")
                detailRow(label: "Status", value: store.status.rawValue.capitalized, icon: "circle.fill", valueColor: statusColor(for: store.status))
            }
        }
    }
    
    private var managerSection: some View {
        FormSectionCard(title: "Assigned Manager", icon: "person.fill") {
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
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    private var employeesSection: some View {
        FormSectionCard(title: "Employees", icon: "person.3.fill") {
            if isLoadingEmployees {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if employees.isEmpty {
                Text("No employees assigned to this store.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(employees) { employee in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(uiColor: .systemGray5))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(employeeInitials(for: employee.fullName))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.primary)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(employee.fullName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                Text(employee.designation ?? "Employee")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                        if employee.id != employees.last?.id {
                            Divider()
                        }
                    }
                }
            }
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
