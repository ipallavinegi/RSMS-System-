import SwiftUI

struct ManagersView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var dataManager = RSMSDataManager.shared
    @State private var searchText = ""
    @State private var showingAddMember = false
    @State private var memberToEdit: Manager? = nil
    @State private var selectedManagerForDetails: Manager? = nil
    private let cardWidth: CGFloat = 300
    
    var filteredMembers: [Manager] {
        let members = dataManager.managers
        return members.filter { member in
            searchText.isEmpty || member.name.localizedCaseInsensitiveContains(searchText) || member.role.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        if dataManager.isLoading && dataManager.managers.isEmpty {
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.4)
                Text("Loading manager…")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemGroupedBackground))
        } else {
            VStack(spacing: 0) {
                // Header (same as before)
                headerView
                
                // Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: cardWidth, maximum: cardWidth), spacing: 20)], spacing: 20) {
                        ForEach(filteredMembers) { member in
                            ManagerCard(member: member, onEdit: {
                                memberToEdit = member
                            }, onDelete: {
                                dataManager.removeManager(member)
                            }, onRestore: {
                                var restored = member
                                restored.isArchived = false
                                dataManager.updateManager(restored)
                            })
                            .frame(width: cardWidth)
                            .onTapGesture {
                                selectedManagerForDetails = member
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, sizeClass == .compact ? 16 : 32)
                    .padding(.top, 32)
                    .padding(.bottom, 140)
                }
                .background(Color(uiColor: .systemGroupedBackground))
            }
            .alert("Error", isPresented: Binding(
                get: { dataManager.errorMessage != nil },
                set: { if !$0 { dataManager.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { dataManager.errorMessage = nil }
            } message: {
                Text(dataManager.errorMessage ?? "")
            }
            .onAppear {
                Task { await dataManager.fetchManager() }
            }
            .sheet(isPresented: $showingAddMember) {
                ManagerForm(memberToEdit: nil, onDismiss: {
                    showingAddMember = false
                }, onSave: { member in
                    dataManager.addManager(member)
                    showingAddMember = false
                })
            }
            .sheet(item: $memberToEdit) { member in
                ManagerForm(memberToEdit: member, onDismiss: {
                    memberToEdit = nil
                }, onSave: { updatedMember in
                    dataManager.updateManager(updatedMember)
                    memberToEdit = nil
                })
            }
            .sheet(item: $selectedManagerForDetails) { member in
                ManagerDetailModalView(manager: member, onDismiss: {
                    selectedManagerForDetails = nil
                })
            }
            .navigationTitle("Managers")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .statusBarHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search manager, roles, or locations...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(Capsule())
                
                Button(action: { showingAddMember = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Create")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, sizeClass == .compact ? 16 : 32)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    private var filterBar: some View {
        EmptyView()
    }
}

#Preview {
    ManagersView()
}
