//
//  ReportHeaderView.swift
//  Admin_RSMS
//
//  Top header for the Audit & Compliance tab.
//    Row 1: Title + subtitle (left), live status (right)
//    Row 2: Store filter, Date filter (left), Export (right)
//

import SwiftUI

struct ReportHeaderView: View {
    @ObservedObject var viewModel: AuditLogsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Audit & Compliance")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    Text("Operational health and risk across the network.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                liveStatus
            }

            HStack(spacing: 10) {
                storeMenu
                dateMenu
                Spacer()
                exportMenu
            }
        }
    }

    // MARK: - Filters

    private var storeMenu: some View {
        Menu {
            Button("All Stores") { viewModel.complianceStoreId = nil }
            ForEach(viewModel.stores) { store in
                Button(store.name) { viewModel.complianceStoreId = store.id }
            }
        } label: {
            chipLabel(icon: "storefront", text: storeLabel)
        }
        .glassChip()
    }

    private var dateMenu: some View {
        Menu {
            ForEach(AuditDateFilter.allCases) { option in
                Button(option.rawValue) { viewModel.complianceDateFilter = option }
            }
        } label: {
            chipLabel(icon: "calendar", text: viewModel.complianceDateFilter.rawValue)
        }
        .glassChip()
    }

    private var exportMenu: some View {
        Menu {
            Button { viewModel.exportPDF() } label: {
                Label("PDF Summary", systemImage: "doc.richtext")
            }
            Button { viewModel.exportExceptionsCSV() } label: {
                Label("CSV — Exceptions", systemImage: "tablecells")
            }
            Button { viewModel.exportComplianceCSV() } label: {
                Label("CSV — Compliance Scores", systemImage: "chart.bar.doc.horizontal")
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "square.and.arrow.up")
                Text("Export")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.rsmsBlue)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
        }
        .glassChip()
    }

    private func chipLabel(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
            Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold))
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(.primary)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    // MARK: - Live status

    private var liveStatus: some View {
        Button {
            viewModel.isLiveStreamActive.toggle()
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.isLiveStreamActive ? Color.green : Color.secondary)
                    .frame(width: 6, height: 6)
                Text(viewModel.isLiveStreamActive ? "Live" : "Paused")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var storeLabel: String {
        guard let id = viewModel.complianceStoreId,
              let store = viewModel.stores.first(where: { $0.id == id })
        else { return "All Stores" }
        return store.name
    }
}
