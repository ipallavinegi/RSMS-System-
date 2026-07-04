//
//  ActivityTrailCard.swift
//  Admin_RSMS
//
//  Merges the two timeline-style sections — the curated "Recent
//  Activity" feed (derived from inventory_exceptions + cycle_counts)
//  and the raw "System Audit Trail" (straight from audit_logs) — into
//  a single card with a segmented control. Same two data sources as
//  before, nothing removed; they just no longer read as two near-
//  identical cards stacked on top of each other.
//

import SwiftUI

struct ActivityTrailCard: View {
    @ObservedObject var viewModel: AuditLogsViewModel
    @State private var mode: Mode = .highlights

    private enum Mode: String, CaseIterable, Identifiable {
        case highlights = "Highlights"
        case trail      = "Full Trail"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            switch mode {
            case .highlights: highlightsList
            case .trail:      trailList
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private var header: some View {
        HStack {
            Image(systemName: mode == .highlights ? "clock.arrow.circlepath" : "list.bullet.clipboard")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.rsmsBlue)
            Text(mode == .highlights ? "Recent Activity" : "System Audit Trail")
                .font(.system(size: 16, weight: .semibold))
            Spacer()
            Picker("View", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .frame(width: 190)
            .labelsHidden()
        }
    }

    // MARK: - Highlights (curated feed)

    private var highlightItems: [ActivityItem] { Array(viewModel.complianceSummary.recentActivity.prefix(10)) }

    private var groupedByDay: [(day: Date, items: [ActivityItem])] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: highlightItems) { cal.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { ($0, groups[$0]!.sorted { $0.date > $1.date }) }
    }

    @ViewBuilder
    private var highlightsList: some View {
        if highlightItems.isEmpty {
            AuditEmptyState(icon: "tray", text: "No recent events for the selected filters.")
        } else {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(groupedByDay, id: \.day) { group in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(dayLabel(group.day))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)

                        ForEach(group.items) { item in
                            Button {
                                viewModel.inspectorContent = .activityDetail(item)
                            } label: {
                                highlightRow(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func highlightRow(_ item: ActivityItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(item.tint)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.title)
                    .font(.system(size: 12.5, weight: .medium))
                Text(item.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(item.date.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary.opacity(0.8))
        }
    }

    private func dayLabel(_ day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "TODAY" }
        if Calendar.current.isDateInYesterday(day) { return "YESTERDAY" }
        return day.formatted(date: .abbreviated, time: .omitted).uppercased()
    }

    // MARK: - Full trail (raw audit_logs)

    @ViewBuilder
    private var trailList: some View {
        if viewModel.isLoading && viewModel.filteredLogs.isEmpty {
            HStack(spacing: 12) {
                ProgressView()
                Text("Loading audit data…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else if viewModel.filteredLogs.isEmpty {
            AuditEmptyState(icon: "doc.text.magnifyingglass", text: "No audit events for this period.")
        } else {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(viewModel.filteredLogs.count) entries")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                LazyVStack(spacing: 0) {
                    ForEach(viewModel.filteredLogs) { item in
                        AuditTrailRow(item: item)
                        if item.id != viewModel.filteredLogs.last?.id {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Row

private struct AuditTrailRow: View {
    let item: AuditLogDisplayItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Module badge
            Text(item.module.prefix(3).uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.rsmsBlue)
                .frame(width: 36, height: 36)
                .background(Color.rsmsBlue.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.action)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Spacer()
                    Text(item.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
                Text(item.userName)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text(item.module)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 10)
    }
}
