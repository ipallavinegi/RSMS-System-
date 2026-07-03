import Foundation

enum PromotionStatus: String, CaseIterable, Identifiable {
    case all = "All" // For filtering purposes
    case active = "Active"
    case scheduled = "Scheduled"
    case completed = "Completed"
    
    var id: String { rawValue }
}

struct Promotion: Identifiable, Hashable {
    let id: UUID
    let title: String
    let subtitle: String
    let dateRange: String
    let status: String
    let imageURL: String?
}

// Sample Data
enum PromotionSampleData {
    static let promos: [Promotion] = [
        Promotion(id: UUID(), title: "Summer Sale 2024", subtitle: "Seasonal Campaign", dateRange: "Jun 1 - Aug 31", status: "Active", imageURL: nil),
        Promotion(id: UUID(), title: "Weekend Flash Deal", subtitle: "Electronics Focus", dateRange: "Oct 12 - Oct 14", status: "Scheduled", imageURL: nil),
        Promotion(id: UUID(), title: "Buy 1 Get 1 Free", subtitle: "Apparel & Basics", dateRange: "Ongoing", status: "Active", imageURL: nil),
        Promotion(id: UUID(), title: "New Arrival Promo", subtitle: "Home Goods Launch", dateRange: "Sep 1 - Sep 15", status: "Completed", imageURL: nil),
        Promotion(id: UUID(), title: "Holiday Pre-Sale", subtitle: "Storewide Clearance", dateRange: "Nov 20 - Nov 25", status: "Scheduled", imageURL: nil)
    ]
}
