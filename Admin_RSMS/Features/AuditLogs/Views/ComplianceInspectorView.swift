//
//  ComplianceInspectorView.swift
//  Admin_RSMS
//
//  Bottom-sheet inspector dispatching on InspectorContent.
//  Each case shows a focused drill-down view so the main screen stays
//  summarized. Navigation between cases (e.g. hotspot → store detail)
//  is handled by swapping viewModel.inspectorContent.
//

import SwiftUI

struct ComplianceInspectorView: View {
    let content: InspectorContent
    @ObservedObject var viewModel: AuditLogsViewModel

    var body: some View {
        Group {
            switch content {
            case .complianceScore(let summary):
                ComplianceScoreInspector(summary: summary, viewModel: viewModel)
            case .allExceptions(let summary):
                AllExceptionsInspector(summary: summary, viewModel: viewModel)
            case .auditHealthScore(let summary):
                AuditHealthScoreInspector(summary: summary)
            case .exceptionGroup(let group, let records):
                ExceptionGroupInspector(group: group, records: records, viewModel: viewModel)
            case .store(let storeSummary):
                StoreDetailInspector(summary: storeSummary)
            case .severityGroup(let severity, let records):
                SeverityGroupInspector(severity: severity, records: records, viewModel: viewModel)
            case .activityDetail(let item):
                ActivityDetailInspector(item: item)
            }
        }
        .navigationTitle(content.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Navigation title helper

private extension InspectorContent {
    var navigationTitle: String {
        switch self {
        case .complianceScore:  return "Compliance Score"
        case .allExceptions:    return "Open Exceptions"
        case .auditHealthScore: return "Audit Health Score"
        case .exceptionGroup(let g, _): return g.title
        case .store(let s):     return s.storeName
        case .severityGroup(let sev, _): return "\(sev) Exceptions"
        case .activityDetail(let a): return a.title
        }
    }
}

// MARK: - Compliance Score Inspector

private struct ComplianceScoreInspector: View {
    let summary: ComplianceSummary
    @ObservedObject var viewModel: AuditLogsViewModel

    var body: some View {
        List {
            Section("Score") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(summary.complianceScore)")
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                        Text(summary.complianceRating.rawValue)
                            .font(.headline)
                            .foregroundStyle(summary.complianceRating.tint)
                    }
                    Spacer()
                    deltaLabel(summary.complianceScoreDeltaPct)
                }
            }
            if !summary.riskHotspots.isEmpty {
                Section("Stores at Risk (\(summary.riskHotspots.count))") {
                    ForEach(summary.riskHotspots) { hotspot in
                        Button {
                            viewModel.inspectorContent = .store(hotspot.healthSummary)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(hotspot.storeName).font(.subheadline.weight(.medium))
                                    Text("\(hotspot.openIssuesTotal) open issues")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(Int(hotspot.overallScore))")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(hotspot.rating.tint)
                                Image(systemName: "chevron.right")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - All Exceptions Inspector

private struct AllExceptionsInspector: View {
    let summary: ComplianceSummary
    @ObservedObject var viewModel: AuditLogsViewModel

    var body: some View {
        List {
            Section("Total Open: \(summary.totalOpenExceptions)") {
                ForEach(summary.exceptionCounts) { ex in
                    Button {
                        viewModel.inspectorContent = .exceptionGroup(
                            ex,
                            viewModel.exceptionRecords(for: ex)
                        )
                    } label: {
                        HStack {
                            Image(systemName: ex.icon)
                                .foregroundStyle(ex.severity.tint)
                                .frame(width: 24)
                            Text(ex.title).font(.subheadline)
                            Spacer()
                            Text("\(ex.count)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(ex.count > 0 ? .primary : .secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(ex.count == 0)
                }
            }
        }
    }
}

// MARK: - Audit Health Score Inspector

private struct AuditHealthScoreInspector: View {
    let summary: ComplianceSummary

    var body: some View {
        List {
            Section("Score") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(summary.auditHealthScore)")
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                        Text(summary.auditHealthRating.rawValue)
                            .font(.headline)
                            .foregroundStyle(summary.auditHealthRating.tint)
                    }
                    Spacer()
                    deltaLabel(summary.auditHealthDeltaPct)
                }
            }
            Section("How it's calculated") {
                Text("The Audit Health Score is derived from open critical/high/medium exceptions, pending urgent stock requests, at-risk shipments (dispatched > 5 days without verification), and overdue cycle counts. Higher penalties reduce the score from 100.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Exception Group Inspector

private struct ExceptionGroupInspector: View {
    let group: ExceptionTypeCount
    let records: [AInventoryException]
    @ObservedObject var viewModel: AuditLogsViewModel

    var body: some View {
        List {
            if records.isEmpty {
                Section { Text("No open records for this exception type.").foregroundStyle(.secondary) }
            } else {
                Section("\(records.count) open") {
                    ForEach(records) { ex in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(viewModel.storeName(forExceptionStoreId: ex.storeId))
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                priorityBadge(ex.priority)
                            }
                            if let remarks = ex.remarks {
                                Text(remarks).font(.caption).foregroundStyle(.secondary)
                            }
                            Text(ex.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
}

// MARK: - Store Detail Inspector

private struct StoreDetailInspector: View {
    let summary: StoreHealthSummary

    var body: some View {
        List {
            Section("Health Scores") {
                scoreRow("Overall",   value: summary.overallScore,   tint: summary.rating.tint)
                scoreRow("Sales",     value: summary.salesScore,     tint: .rsmsBlue)
                scoreRow("Inventory", value: summary.inventoryScore, tint: .orange)
                scoreRow("Customer",  value: summary.customerScore,  tint: .purple)
            }
            if !summary.openIssues.isEmpty {
                Section("Open Issues (\(summary.openIssues.count))") {
                    ForEach(summary.openIssues) { issue in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(issue.label).font(.subheadline)
                                Text(issue.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            priorityBadge(issue.priority)
                        }
                    }
                }
            }
            if !summary.recentActivity.isEmpty {
                Section("Recent Activity") {
                    ForEach(summary.recentActivity) { item in
                        HStack(spacing: 10) {
                            Image(systemName: item.icon).foregroundStyle(item.tint)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title).font(.subheadline)
                                Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func scoreRow(_ label: String, value: Double, tint: Color) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(String(format: "%.1f", value))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
        }
    }
}

// MARK: - Severity Group Inspector

private struct SeverityGroupInspector: View {
    let severity: String
    let records: [AInventoryException]
    @ObservedObject var viewModel: AuditLogsViewModel

    var body: some View {
        List {
            if records.isEmpty {
                Section { Text("No open \(severity.lowercased()) exceptions.").foregroundStyle(.secondary) }
            } else {
                Section("\(records.count) \(severity.lowercased()) open") {
                    ForEach(records) { ex in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(ex.exceptionType).font(.subheadline.weight(.medium))
                                Spacer()
                                Text(viewModel.storeName(forExceptionStoreId: ex.storeId))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            if let remarks = ex.remarks {
                                Text(remarks).font(.caption).foregroundStyle(.secondary)
                            }
                            Text(ex.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
}

// MARK: - Activity Detail Inspector

private struct ActivityDetailInspector: View {
    let item: ActivityItem

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: item.icon)
                        .font(.title2)
                        .foregroundStyle(item.tint)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title).font(.headline)
                        Text(item.subtitle).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
            }
            Section("Timestamp") {
                Text(item.date.formatted(date: .complete, time: .complete))
                    .font(.subheadline)
            }
        }
    }
}

// MARK: - Shared helpers

private func deltaLabel(_ pct: Double) -> some View {
    let up = pct >= 0
    return HStack(spacing: 2) {
        Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
        Text(String(format: "%.1f%%", abs(pct)))
    }
    .font(.subheadline.weight(.semibold))
    .foregroundStyle(up ? Color.green : Color.red)
}

private func priorityBadge(_ priority: String) -> some View {
    let color: Color = {
        switch priority {
        case "Critical": return Color(red: 0.95, green: 0.15, blue: 0.15)
        case "High":     return Color(red: 1.0,  green: 0.55, blue: 0.0)
        case "Medium":   return Color(red: 0.95, green: 0.75, blue: 0.10)
        default:         return Color(red: 0.2,  green: 0.78, blue: 0.35)
        }
    }()
    return Text(priority)
        .font(.system(size: 11, weight: .semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.15), in: Capsule())
        .foregroundStyle(color)
}
