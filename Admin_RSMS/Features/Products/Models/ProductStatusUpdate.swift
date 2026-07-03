import Foundation

/// Partial update payload — only ever writes approval_status, nothing else on the row.
struct ProductStatusUpdate: Encodable {
    let approval_status: String
}
