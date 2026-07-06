import SwiftUI
import UIKit

struct StoreCard: View {
    let store: AdminStore
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onRestore: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Hero Image Section
            ZStack(alignment: .topTrailing) {
                if let imageUrlString = store.imageUrl, let url = URL(string: imageUrlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
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
                        .frame(height: 160)
                        .clipped()
                } else {
                    fallbackImage
                }
                
                if store.isArchived {
                    Text("ARCHIVED")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .padding(12)
                }
            }
            .frame(height: 160)
            
            // Content Section
            VStack(alignment: .leading, spacing: 14) {
                // Title Row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.circle")
                                .font(.system(size: 11))
                            Text(store.address)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .lineLimit(1)
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
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                            .padding(.bottom, 8)
                            .contentShape(Rectangle())
                    }
                }
                
                // Manager & Status
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(uiColor: .systemGray5))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(store.managerInitials)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.primary)
                        )
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text("MANAGER")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                        Text(store.managerName)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    statusBadge(for: store.status)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
        .cardShadow()
        .opacity(store.isArchived ? 0.6 : 1.0)
        .grayscale(store.isArchived ? 1.0 : 0.0)
    }
    
    @ViewBuilder
    private func statusBadge(for status: StoreStatus) -> some View {
        let isMaintenance = status == .maintenance
        let isInventory = status == .inventory
        
        let fgColor = isMaintenance ? Color.purple : (isInventory ? Color.orange : Color.teal)
        let bgColor = fgColor.opacity(0.15)
        
        Text(status.rawValue.uppercased())
            .font(.system(size: 9, weight: .heavy))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(bgColor)
            .foregroundColor(fgColor)
            .clipShape(Capsule())
    }
    
    private var fallbackImage: some View {
        Rectangle()
            .fill(Color(uiColor: .systemGray5))
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .overlay(
                Image(systemName: "photo.fill")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            )
    }
}
