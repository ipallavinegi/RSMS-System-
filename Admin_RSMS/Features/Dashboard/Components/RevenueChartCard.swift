import SwiftUI
import Charts

struct RevenueChartCard: View {
    let salesSummary: SalesSummary
    @Binding var selectedPeriod: RevenuePeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Row
            ViewThatFits(in: .horizontal) {
                // Wide layout
                HStack(alignment: .top) {
                    headerText
                    Spacer(minLength: 16)
                    periodPicker
                }
                
                // Narrow layout: Stack them
                VStack(alignment: .leading, spacing: 12) {
                    headerText
                    periodPicker
                }
            }
            
            // Chart
            if !salesSummary.trend.isEmpty {
                Chart {
                    ForEach(salesSummary.trend) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Revenue", point.amount)
                        )
                        .interpolationMethod(.catmullRom) // Smooth curves
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .foregroundStyle(Color.blue)
                        
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Revenue", point.amount)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.day().month())
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let amount = value.as(Double.self) {
                                Text("₹\(Int(amount / 1000))k")
                            }
                        }
                    }
                }
                .frame(height: 275)
                .padding(.top, 16)
            } else {
                Spacer()
                    .frame(height: 275)
            }
        }
        .padding(24)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    // Extracted Subviews for Responsive Header
    private var headerText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TOTAL REVENUE")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .tracking(1.2)
            
            Text("₹\(Int(salesSummary.actual).formattedIndian)")
                .font(.system(size: 38, weight: .bold, design: .rounded))
            
            HStack(spacing: 4) {
                Image(systemName: salesSummary.variance < 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                Text("\(String(format: "%.1f", abs(salesSummary.variancePercent * 100)))% vs last period")
            }
            .font(.subheadline.bold())
            .foregroundStyle(salesSummary.variance < 0 ? Color.red : Color.green)
        }
    }
    
    private var periodPicker: some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(RevenuePeriod.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 200)
    }
}
