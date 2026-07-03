import SwiftUI
import UIKit

struct StoreCard: View {
    let store: AdminStore
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onRestore: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image Section
            ZStack(alignment: .topTrailing) {
                if let imageUrlString = store.imageUrl, let url = URL(string: imageUrlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .clipped()
                        case .failure:
                            fallbackImage
                        @unknown default:
                            fallbackImage
                        }
                    }
                } else if let imageData = store.imageData, let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 120)
                        .clipped()
                } else {
                    fallbackImage
                }
                if store.isArchived {
                    Text("DELETED")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                        .padding(8)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(6)
            
            // Info Section
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle")
                            Text(store.address)
                        }
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    }
                    Spacer()
                    Menu {
                        Button(action: onEdit) {
                            Label("Edit Store", systemImage: "pencil")
                        }
                        
                        if store.isArchived {
                            if let onRestore = onRestore {
                                Button(action: onRestore) {
                                    Label("Restore Store", systemImage: "arrow.uturn.backward")
                                }
                            }
                        } else {
                            Button(role: .destructive, action: onDelete) {
                                Label("Remove Store", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                }
                
                Divider()
                
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(store.managerInitials)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.primary)
                        )
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text("MANAGER")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(store.managerName)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    
                    Spacer()
                    
                    // Moved Status Label to the bottom
                    Text(store.status.rawValue)
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 3)
        .opacity(store.isArchived ? 0.6 : 1.0)
        .grayscale(store.isArchived ? 1.0 : 0.0)
    }
    
    private var statusColor: Color {
        switch store.status {
        case .active: return Color.teal
        case .maintenance: return Color.purple
        case .inventory: return Color.orange
        }
    }
    
    private var fallbackImage: some View {
        Rectangle()
            .fill(LinearGradient(colors: [Color(white: 0.9), Color(white: 0.95)], startPoint: .top, endPoint: .bottom))
            .frame(maxWidth: .infinity)
            .frame(height: 120)
    }
}
