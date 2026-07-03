import SwiftUI
import Charts

struct RevenueChartCard: View {
    let salesSummary: SalesSummary
    @Binding var selectedPeriod: RevenuePeriod

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Row
            HStack(alignment: .top) {
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
                
                Spacer()
                
                // Segmented picker
                HStack(spacing: 0) {
                    ForEach(RevenuePeriod.allCases) { period in
                        Text(period.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedPeriod == period ? Color.white : Color.clear)
                            .clipShape(Capsule())
                            .shadow(color: selectedPeriod == period ? Color.black.opacity(0.05) : Color.clear, radius: 2, y: 1)
                            .foregroundColor(selectedPeriod == period ? .primary : .secondary)
                            .onTapGesture {
                                withAnimation {
                                    selectedPeriod = period
                                }
                            }
                    }
                }
                .padding(4)
                .background(Color(uiColor: .systemGray6))
                .clipShape(Capsule())
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
                        AxisValueLabel(format: .dateTime.month())
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
                .frame(height: 220)
                .padding(.top, 16)
            } else {
                Spacer()
                    .frame(height: 220)
            }
        }
        .padding(24)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
}
