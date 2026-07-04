//
//  ExceptionsOverviewCard.swift
//  Admin_RSMS
//
//  Replaces the old separate Risk Distribution bar chart + 5-tile
//  Operational Exceptions grid with one card. Both halves read from the
//  same table (`inventory_exceptions`) at two different angles —
//  severity on the left, type on the right — so they belong together.
//  The row titles are exactly the schema's `exception_type` values
//  (Missing Item, Extra Item, Wrong Quantity, Damaged Product,
//  Shipment Mismatch, Store Mismatch) — no invented categories like
//  "Planogram".
//

import SwiftUI

struct ExceptionsOverviewCard: View {
    @ObservedObject var viewModel: AuditLogsViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass

    private var buckets: [RiskSeverityBucket] { viewModel.complianceSummary.severityDistribution }
    private var maxCount: Int { max(buckets.map(\.count).max() ?? 0, 1) }
    private var totalOpen: Int { buckets.reduce(0) { $0 + $1.count } }
    private var types: [ExceptionTypeCount] { viewModel.complianceSummary.exceptionCounts }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(icon: "exclamationmark.triangle", title: "Exceptions & Risk", trailing: "\(totalOpen) open")

            if sizeClass == .regular {
                HStack(alignment: .top, spacing: 28) {
                    severityColumn.frame(maxWidth: .infinity)
                    Divider()
                    typeColumn.frame(maxWidth: .infinity)
                }
            } else {
                severityColumn
                Divider()
                typeColumn
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - By severity

    private var severityColumn: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BY SEVERITY")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            if totalOpen == 0 {
                AuditEmptyState(icon: "checkmark.shield", text: "No open exceptions.")
            } else {
                VStack(spacing: 12) {
                    ForEach(buckets) { bucket in
                        Button {
                            viewModel.inspectorContent = .severityGroup(
                                bucket.severity,
                                viewModel.exceptionRecords(forSeverity: bucket.severity)
                            )
                        } label: {
                            severityRow(bucket)
                        }
                        .buttonStyle(.plain)
                        .disabled(bucket.count == 0)
                    }
                }
            }
        }
    }

    private func severityRow(_ bucket: RiskSeverityBucket) -> some View {
        HStack(spacing: 12) {
            Text(bucket.severity)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 56, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.08))
                    Capsule()
                        .fill(bucket.tint.opacity(bucket.count == 0 ? 0.2 : 0.8))
                        .frame(width: max(6, geo.size.width * CGFloat(bucket.count) / CGFloat(maxCount)))
                }
            }
            .frame(height: 14)

            Text("\(bucket.count)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(bucket.count > 0 ? bucket.tint : .secondary)
                .frame(width: 22, alignment: .trailing)
        }
    }

    // MARK: - By type

    private var typeColumn: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("BY TYPE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                ForEach(types) { type in
                    Button {
                        viewModel.inspectorContent = .exceptionGroup(type, viewModel.exceptionRecords(for: type))
                    } label: {
                        typeRow(type)
                    }
                    .buttonStyle(.plain)
                    .disabled(type.count == 0)
                }
            }
        }
    }

    private func typeRow(_ type: ExceptionTypeCount) -> some View {
        HStack(spacing: 10) {
            Circle().fill(type.severity.tint).frame(width: 7, height: 7)

            Text(type.title)
                .font(.system(size: 13))
                .foregroundStyle(.primary)

            Spacer()

            deltaText(type.weeklyDelta)

            Text("\(type.count)")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(type.count > 0 ? .primary : .secondary)
                .frame(width: 26, alignment: .trailing)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func deltaText(_ d: Int) -> some View {
        if d != 0 {
            Text("\(d > 0 ? "+" : "−")\(abs(d))")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(d > 0 ? Color.red : Color.green)
        }
    }
}
