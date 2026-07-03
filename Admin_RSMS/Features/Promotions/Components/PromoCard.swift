import SwiftUI

struct PromoCard: View {
    let promotion: Promotion
    
    // Explicit sizing to match the grid requirement
    private let imageHeight: CGFloat = 160
    
    var body: some View {
        VStack(spacing: 0) {
            // Hero Image
            ZStack {
                Rectangle()
                    .fill(Color(uiColor: .systemGray5))
                
                // Using sf symbol as placeholder since we don't have real remote URLs
                Image(systemName: "photo.fill")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
            }
            .frame(height: imageHeight)
            .clipped()
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(promotion.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(promotion.subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Text(promotion.dateRange)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
                
                statusBadge(for: promotion.status)
                    .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    @ViewBuilder
    private func statusBadge(for status: String) -> some View {
        let isScheduled = status == "Scheduled"
        let isCompleted = status == "Completed"
        
        let fgColor = isCompleted ? Color.secondary : (isScheduled ? Color.blue : Color.green)
        let bgColor = fgColor.opacity(0.15)
        
        Text(status)
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(bgColor)
            .foregroundColor(fgColor)
            .clipShape(Capsule())
    }
}
