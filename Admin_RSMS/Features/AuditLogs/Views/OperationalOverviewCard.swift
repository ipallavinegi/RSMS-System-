//
//  OperationalOverviewCard.swift
//  Admin_RSMS
//
//  Replaces the old separate Trend Chart + 3 floating KPI tiles with one
//  card: the chart on top, the three headline numbers underneath it.
//  The chart's range now follows the same Store/Date filter in the
//  header — there is no second, duplicate range control inside the
//  card anymore.
//

import SwiftUI
import Charts

struct OperationalOverviewCard: View {
    @ObservedObject var viewModel: AuditLogsViewModel
    @State private var selectedPoint: OperationalTrendPoint?

    private var s: ComplianceSummary { viewModel.complianceSummary }

    /// Trend window follows the header's date filter instead of a
    /// second, duplicate control living inside this card.
    private var trendDays: Int {
        switch viewModel.complianceDateFilter {
        case .last7Days:   return 7
        case .last30Days:  return 30
        case .lastQuarter: return 90
        case .lastYear:    return 365
        case .allTime:     return 180   // cap "All Time" so the chart stays readable
        }
    }

    private var points: [OperationalTrendPoint] { viewModel.trendPoints(forDays: trendDays) }
    private var isTrendEmpty: Bool { points.allSatisfy { $0.complianceScore == 0 && $0.inventoryAccuracy == 0 } }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            header

            if isTrendEmpty {
                AuditEmptyState(icon: "chart.line.uptrend.xyaxis", text: "No trend data for \(viewModel.complianceDateFilter.rawValue.lowercased()).")
                    .frame(height: 160)
            } else {
                chart
                    .frame(height: 220)

                if let selectedPoint {
                    selectionRow(selectedPoint)
                }
            }

            Divider().opacity(0.5)

            metricsRow
        }
        .padding(24)
        .glassCard()
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Operational Health")
                .font(.system(size: 18, weight: .semibold))
            Spacer()
            HStack(spacing: 16) {
                legend(color: .rsmsBlue, label: "Compliance")
                legend(color: .green, label: "Accuracy")
            }
        }
    }

    private func legend(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Chart

    @ViewBuilder
    private var chart: some View {
        Chart {
            ForEach(points) { point in
                LineMark(
                    x: .value("Day", point.day, unit: .day),
                    y: .value("Compliance", point.complianceScore),
                    series: .value("Metric", "Compliance")
                )
                .foregroundStyle(Color.rsmsBlue)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                .interpolationMethod(.catmullRom)
            }
            ForEach(points) { point in
                LineMark(
                    x: .value("Day", point.day, unit: .day),
                    y: .value("Inventory", point.inventoryAccuracy),
                    series: .value("Metric", "Inventory")
                )
                .foregroundStyle(Color.green)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                .interpolationMethod(.catmullRom)
            }
            if let selectedPoint {
                RuleMark(x: .value("Day", selectedPoint.day, unit: .day))
                    .foregroundStyle(Color.secondary.opacity(0.2))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
        }
        .chartYScale(domain: 0...100)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, points.count / 6))) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.06))
            }
        }
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                AxisValueLabel {
                    if let v = value.as(Int.self) {
                        Text("\(v)").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                }
                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.06))
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle().fill(Color.clear).contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let day: Date = proxy.value(atX: value.location.x - geo[proxy.plotAreaFrame].origin.x)
                                else { return }
                                selectedPoint = points.min {
                                    abs($0.day.timeIntervalSince(day)) < abs($1.day.timeIntervalSince(day))
                                }
                            }
                    )
            }
        }
    }

    private func selectionRow(_ point: OperationalTrendPoint) -> some View {
        Button {
            viewModel.inspectorContent = .complianceScore(s)
        } label: {
            HStack(spacing: 20) {
                Text(point.day.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Compliance \(Int(point.complianceScore.rounded()))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.rsmsBlue)
                Text("Accuracy \(Int(point.inventoryAccuracy.rounded()))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.green)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }

    // MARK: - Metrics row

    private var metricsRow: some View {
        HStack(alignment: .top, spacing: 0) {
            metric(
                label: "Compliance Score", value: "\(s.complianceScore)",
                caption: "\(s.complianceRating.rawValue) · \(deltaText(s.complianceScoreDeltaPct))",
                tint: s.complianceRating.tint
            ) { viewModel.inspectorContent = .complianceScore(s) }

            Divider().frame(height: 44)

            metric(
                label: "Open Issues", value: "\(s.totalOpenExceptions)",
                caption: "\(s.criticalExceptionsCount) critical",
                tint: s.totalOpenExceptions > 0 ? .orange : .secondary
            ) { viewModel.inspectorContent = .allExceptions(s) }

            Divider().frame(height: 44)

            metric(
                label: "Audit Score", value: "\(s.auditHealthScore)",
                caption: "\(s.auditHealthRating.rawValue) · \(deltaText(s.auditHealthDeltaPct))",
                tint: s.auditHealthRating.tint
            ) { viewModel.inspectorContent = .auditHealthScore(s) }
        }
    }

    private func metric(label: String, value: String, caption: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                MetricLabel(text: label)
                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(tint)
                Text(caption)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    private func deltaText(_ pct: Double) -> String {
        let arrow = pct >= 0 ? "▲" : "▼"
        return "\(arrow) \(String(format: "%.1f", abs(pct)))%"
    }
}
