import SwiftUI

struct ManagerCard: View {
    let member: Manager
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onRestore: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Actions Menu
            HStack {
                Spacer()
                Menu {
                    Button(action: onEdit) {
                        Label("Edit Member", systemImage: "pencil")
                    }
                    
                    if member.isArchived {
                        if let onRestore = onRestore {
                            Button(action: onRestore) {
                                Label("Restore Member", systemImage: "arrow.uturn.backward")
                            }
                        }
                    } else {
                        Button(role: .destructive, action: onDelete) {
                            Label("Remove Member", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .padding(12)
                        .contentShape(Rectangle())
                }
            }
            
            // Profile Section
            VStack(spacing: 8) {
                Group {
                    if let imageName = member.imageName {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Circle()
                            .fill(Color(uiColor: .systemGray5))
                            .overlay(
                                Text(member.initials)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.primary)
                            )
                    }
                }
                .frame(width: 54, height: 54)
                .clipShape(Circle())
                .overlay(
                    Group {
                        if member.isArchived {
                            Circle()
                                .fill(Color.black.opacity(0.4))
                                .overlay(
                                    Text("DEL")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                )
                
                VStack(spacing: 1) {
                    Text(member.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    Text(member.role)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            .padding(.bottom, 12)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Info Section
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(member.location)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(member.shift)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                if !member.email.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(member.email)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer(minLength: 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
        .cardShadow()
        .opacity(member.isArchived ? 0.6 : 1.0)
        .grayscale(member.isArchived ? 1.0 : 0.0)
    }
}

struct InviteMemberCard: View {
    var onAdd: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 4) {
                Text("Invite Member")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("Add to your team.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Button(action: onAdd) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Add")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.white)
                .cornerRadius(18)
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(red: 0.1, green: 0.2, blue: 0.4))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    HStack {
        InviteMemberCard(onAdd: {})
            .frame(width: 250, height: 300)
        ManagerCard(member: Manager(name: "Sarah Jenkins", role: "Store Manager", location: "Downtown Flagship", shift: "Shift: 09:00 - 18:00", initials: "SJ"), onEdit: {}, onDelete: {}, onRestore: {})
            .frame(width: 250, height: 300)
    }
    .padding()
    .background(Color(uiColor: .systemGray6))
}
