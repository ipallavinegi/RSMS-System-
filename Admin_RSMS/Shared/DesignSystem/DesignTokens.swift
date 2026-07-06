import SwiftUI

// MARK: - Brand Colors
public extension Color {
    static let brandGreen       = Color(hexCode: "#B5D96B")
    static let brandGreenLight  = Color(hexCode: "#E6F4C1")
    static let brandGreenDark   = Color(hexCode: "#6BAF1A")
    static let pageBG           = Color(hexCode: "#F5F5F0")
    static let cardBG           = Color(hexCode: "#FFFFFF")
    static let inputBG          = Color(hexCode: "#F2F2EF")
    static let label1           = Color(hexCode: "#111111")
    static let label2           = Color(hexCode: "#888888")
    static let label3           = Color(hexCode: "#BBBBBB")
    static let separator        = Color(hexCode: "#E8E8E4")
    static let accentOrange     = Color(hexCode: "#F4A261")
    static let accentRed        = Color(hexCode: "#E63946")
    static let accentBlue       = Color(hexCode: "#3A86FF")
    static let accentPurple     = Color(hexCode: "#845EC2")
}

// MARK: - Typography
public extension Font {
    static let heroNumber   = Font.system(size: 52, weight: .black)
    static let heroTitle    = Font.system(size: 32, weight: .bold)
    static let cardTitle    = Font.system(size: 18, weight: .semibold)
    static let bodyPrimary  = Font.system(size: 16, weight: .medium)
    static let bodySecond   = Font.system(size: 14, weight: .regular)
    static let captionMed   = Font.system(size: 12, weight: .medium)
    static let overlineText = Font.system(size: 11, weight: .semibold)
}

// MARK: - Spacing Constants
public struct DS {
    public static let pagePad: CGFloat        = 20
    public static let cardPad: CGFloat        = 20
    public static let cardSpacing: CGFloat    = 16
    public static let sectionSpacing: CGFloat = 28
    public static let cardRadius: CGFloat     = 20
    public static let smallRadius: CGFloat    = 12
    public static let fabRadius: CGFloat      = 22
}

// MARK: - View Modifiers
public extension View {
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
    func chipShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Hex Color Initializer
public extension Color {
    init(hexCode: String) {
        let hexStr = hexCode.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexStr).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
