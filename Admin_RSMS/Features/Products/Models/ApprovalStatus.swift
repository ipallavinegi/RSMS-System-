import Foundation

enum ApprovalStatus: String, CaseIterable, Identifiable {
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"

    var id: String { rawValue }
}

/// Drives the top filter bar. Distinct from `ApprovalStatus` because "All" isn't
/// a real value that ever gets written to `approval_status` on a row — it just
/// means "don't filter."
enum ProductFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case pending = "Pending"

    var id: String { rawValue }

    /// nil means "no filter" (show everything).
    var matchingStatus: ApprovalStatus? {
        switch self {
        case .all: return nil
        case .pending: return .pending
        }
    }
}
