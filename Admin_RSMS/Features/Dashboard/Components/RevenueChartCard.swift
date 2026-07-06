import SwiftUI
import Charts

struct RevenueChartCard: View {
    let salesSummary: SalesSummary
    @Binding var selectedPeriod: RevenuePeriod
    
    @State private var selectedDataPoint: DailySalesPoint?
    @State private var plotWidth: CGFloat = 0
    
    // Computed: find the point with the highest sales
    private var topSalesPoint: DailySalesPoint? {
        salesSummary.trend.max(by: { $0.amount < $1.amount })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Row
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    revenueInfo
                    Spacer()
                    periodPicker
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    revenueInfo
                    periodPicker
                }
            }
            
            // Chart
            if !salesSummary.trend.isEmpty {
                chartView
                    .frame(minHeight: 220, maxHeight: .infinity)
                    .padding(.top, 16)
            } else {
                Spacer()
                    .frame(minHeight: 220, maxHeight: .infinity)
            }
        }
        .padding(24)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(Color.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
        .cardShadow()
    }
    
    // MARK: - Header Subviews
    
    @ViewBuilder
    private var revenueInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TOTAL REVENUE")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .tracking(1.2)
            
            // Show selected point amount or total
            if let selected = selectedDataPoint {
                Text("₹\(Int(selected.amount).formattedIndian)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
            } else {
                Text("₹\(Int(salesSummary.actual).formattedIndian)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
            }
            
            HStack(spacing: 4) {
                if let selected = selectedDataPoint {
                    Text(dateLabel(for: selected.date))
                        .font(.subheadline.bold())
                        .foregroundStyle(.blue)
                } else {
                    Image(systemName: salesSummary.variance < 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                    Text("\(String(format: "%.1f", abs(salesSummary.variancePercent * 100)))% vs last period")
                }
            }
            .font(.subheadline.bold())
            .foregroundStyle(selectedDataPoint != nil ? .blue : (salesSummary.variance < 0 ? Color.red : Color.green))
        }
    }
    
    @ViewBuilder
    private var periodPicker: some View {
        HStack(spacing: 0) {
            ForEach(RevenuePeriod.allCases) { period in
                Text(period.rawValue)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selectedPeriod == period ? Color.white : Color.clear)
                    .clipShape(Capsule())
                    .shadow(color: selectedPeriod == period ? Color.black.opacity(0.05) : Color.clear, radius: 2, y: 1)
                    .foregroundColor(selectedPeriod == period ? .primary : .secondary)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedPeriod = period
                            selectedDataPoint = nil
                        }
                    }
            }
        }
        .padding(4)
        .background(Color(uiColor: .systemGray6))
        .clipShape(Capsule())
    }
    
    // MARK: - Chart View
    
    @ViewBuilder
    private var chartView: some View {
        Chart {
            ForEach(salesSummary.trend) { point in
                // Area fill
                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Revenue", point.amount)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.25), Color.blue.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Main line
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Revenue", point.amount)
                )
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .foregroundStyle(Color.blue)
                
                // Show a point marker for the top sales
                if let topPoint = topSalesPoint, isSameUnit(point.date, topPoint.date), selectedDataPoint == nil {
                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Revenue", point.amount)
                    )
                    .symbolSize(60)
                    .foregroundStyle(Color.blue)
                    .annotation(position: .top, spacing: 8) {
                        topSalesAnnotation(amount: point.amount)
                    }
                }
            }
            
            // Selection rule line + point
            if let selected = selectedDataPoint {
                RuleMark(x: .value("Date", selected.date))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(Color.blue.opacity(0.5))
                
                PointMark(
                    x: .value("Date", selected.date),
                    y: .value("Revenue", selected.amount)
                )
                .symbolSize(100)
                .foregroundStyle(Color.white)
                .annotation(position: .top, spacing: 8) {
                    tooltipView(for: selected)
                }
                
                PointMark(
                    x: .value("Date", selected.date),
                    y: .value("Revenue", selected.amount)
                )
                .symbolSize(50)
                .foregroundStyle(Color.blue)
            }
        }
        .chartXAxis {
            AxisMarks(values: xAxisValues) { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.15))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(xAxisLabel(for: date))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.15))
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text("₹\(yAxisLabel(amount))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let xPosition = value.location.x
                                guard let date: Date = proxy.value(atX: xPosition) else { return }
                                selectNearestPoint(to: date)
                            }
                            .onEnded { _ in
                                // Keep selection visible; tap elsewhere to deselect
                            }
                    )
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedDataPoint = nil
                        }
                    }
            }
        }
        .chartXSelection(value: .init(get: {
            selectedDataPoint?.date
        }, set: { newDate in
            if let newDate {
                selectNearestPoint(to: newDate)
            }
        }))
    }
    
    // MARK: - Tooltip View
    
    private func tooltipView(for point: DailySalesPoint) -> some View {
        VStack(spacing: 4) {
            Text("₹\(Int(point.amount).formattedIndian)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(dateLabel(for: point.date))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.blue)
                .shadow(color: Color.blue.opacity(0.3), radius: 6, y: 3)
        )
    }
    
    // MARK: - Top Sales Annotation
    
    private func topSalesAnnotation(amount: Double) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill")
                .font(.system(size: 8))
            Text("₹\(Int(amount).formattedIndian)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.blue)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    // MARK: - X Axis Configuration
    
    private var xAxisUnit: Calendar.Component {
        switch selectedPeriod {
        case .week:
            return .day
        case .month:
            return .day
        case .year:
            return .month
        }
    }
    
    private var xAxisValues: AxisMarkValues {
        switch selectedPeriod {
        case .week:
            return .stride(by: .day, count: 1)
        case .month:
            return .stride(by: .day, count: 5)
        case .year:
            return .stride(by: .month, count: 1)
        }
    }
    
    private func xAxisLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        switch selectedPeriod {
        case .week:
            formatter.dateFormat = "EEE"  // Mon, Tue, etc.
        case .month:
            formatter.dateFormat = "d MMM" // 1 Jun, 15 Jun, etc.
        case .year:
            formatter.dateFormat = "MMM"   // Jan, Feb, etc.
        }
        return formatter.string(from: date)
    }
    
    // MARK: - Y Axis Label
    
    private func yAxisLabel(_ amount: Double) -> String {
        if amount >= 1_000_000 {
            let value = amount / 100_000
            return String(format: "%.1fL", value)
        } else {
            return "\(Int(amount / 1000))k"
        }
    }
    
    // MARK: - Date Label for tooltip
    
    private func dateLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        switch selectedPeriod {
        case .week:
            formatter.dateFormat = "EEEE, d MMM"    // Thursday, 3 Jul
        case .month:
            formatter.dateFormat = "d MMMM yyyy"     // 3 July 2026
        case .year:
            formatter.dateFormat = "MMMM yyyy"       // July 2026
        }
        return formatter.string(from: date)
    }
    
    // MARK: - Selection Helpers
    
    private func selectNearestPoint(to date: Date) {
        guard !salesSummary.trend.isEmpty else { return }
        
        let nearest = salesSummary.trend.min(by: {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        })
        
        withAnimation(.easeOut(duration: 0.15)) {
            selectedDataPoint = nearest
        }
    }
    
    private func isSameUnit(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .week, .month:
            return calendar.isDate(date1, inSameDayAs: date2)
        case .year:
            return calendar.component(.month, from: date1) == calendar.component(.month, from: date2) &&
                   calendar.component(.year, from: date1) == calendar.component(.year, from: date2)
        }
    }
}
