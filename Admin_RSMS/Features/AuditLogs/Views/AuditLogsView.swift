//
//  AuditLogsView.swift
//  Admin_RSMS
//
//  The Audit & Compliance tab. Layout, top to bottom:
//    Header               — title, Store filter, Time Range filter, Export
//    Operational Overview — trend chart + Compliance/Issues/Audit numbers, one card
//    Exceptions & Risk    — severity + real exception-type breakdown, one card
//    Activity & Trail     — curated feed / raw log, toggled in one card
//
//  Every card/chart/bar/feed tap opens the same inspector sheet so the
//  main screen stays summarized while still allowing full drill-down.
//

import SwiftUI

struct AuditLogsView: View {
    @StateObject private var viewModel = AuditLogsViewModel()
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                ReportHeaderView(viewModel: viewModel)

                OperationalOverviewCard(viewModel: viewModel)

                ExceptionsOverviewCard(viewModel: viewModel)

                ActivityTrailCard(viewModel: viewModel)
            }
            .padding(.horizontal, sizeClass == .regular ? 32 : 16)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
        .background(Color.pageBG)
        .shareSheet(url: $viewModel.exportedFileURL)
        .sheet(item: Binding(
            get: { viewModel.inspectorContent },
            set: { viewModel.inspectorContent = $0 }
        )) { content in
            NavigationStack {
                ComplianceInspectorView(content: content, viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { viewModel.inspectorContent = nil }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

#Preview {
    AuditLogsView()
}
