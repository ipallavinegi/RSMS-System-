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
        Group {
            if dataManager.isLoading && dataManager.managers.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.4)
                    Text("Loading manager…")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.pageBG)
            } else {
                VStack(spacing: 0) {
                    // Grid
                    ScrollView {
                        let columns = sizeClass == .compact ? [GridItem(.flexible(), spacing: 20)] : [GridItem(.adaptive(minimum: 300, maximum: 400), spacing: 20)]
                        LazyVGrid(columns: columns, spacing: 20) {
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
                                .frame(maxWidth: .infinity)
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
                    .background(Color.pageBG)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search managers, roles, or locations...")
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
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddMember = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}

#Preview {
    ManagersView()
}
