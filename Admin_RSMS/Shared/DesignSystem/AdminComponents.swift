import SwiftUI

public struct AdminHeroCard<Content: View>: View {
    public let title: String
    public let subtitle: String
    @ViewBuilder public let content: Content
    
    public init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(subtitle.uppercased())
                .font(Font.overlineText)
                .foregroundColor(Color.white.opacity(0.8))
                .tracking(1.5)
            
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
            
            content
        }
        .padding(DS.cardPad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentPurple)
        .cornerRadius(DS.cardRadius)
        .cardShadow()
    }
}

public struct MetricTile: View {
    public let overline: String
    public let value: String
    public let label: String
    public let icon: String
    public let iconColor: Color
    
    public init(overline: String, value: String, label: String, icon: String, iconColor: Color = .brandGreenDark) {
        self.overline = overline
        self.value = value
        self.label = label
        self.icon = icon
        self.iconColor = iconColor
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(overline.uppercased())
                    .font(Font.overlineText)
                    .foregroundColor(Color.label2)
                    .tracking(1.0)
                Spacer()
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(iconColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.label1)
                
                Text(label)
                    .font(Font.bodySecond)
                    .foregroundColor(Color.label2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBG)
        .cornerRadius(DS.cardRadius)
        .cardShadow()
    }
}

public struct StatusBadge: View {
    public let label: String
    public let backgroundColor: Color
    public let textColor: Color
    
    public init(label: String, backgroundColor: Color, textColor: Color) {
        self.label = label
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
    
    public var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(textColor)
                .frame(width: 6, height: 6)
            Text(label)
                .font(Font.captionMed)
                .foregroundColor(textColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(backgroundColor)
        .cornerRadius(8)
        .chipShadow()
    }
}

public struct ListRowCard<TrailingContent: View>: View {
    public let title: String
    public let subtitle: String
    public let icon: String?
    public let iconColor: Color
    @ViewBuilder public let trailingContent: TrailingContent
    
    public init(title: String, subtitle: String, icon: String? = nil, iconColor: Color = .blue, @ViewBuilder trailingContent: () -> TrailingContent) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.trailingContent = trailingContent()
    }
    
    public var body: some View {
        HStack(spacing: 16) {
            if let icon = icon {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(iconColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color.label1)
                
                Text(subtitle)
                    .font(Font.bodySecond)
                    .foregroundColor(Color.label2)
            }
            
            Spacer()
            
            trailingContent
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 72)
        .background(Color.cardBG)
        .cornerRadius(16)
        .cardShadow()
    }
}
