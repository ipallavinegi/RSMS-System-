//
//  AuditLogExporter.swift
//  Admin_RSMS
//
//  Generates PDF summaries and CSV exports from the Audit & Compliance
//  Center data, writing them to a temp URL the share sheet can pick up.
//

import Foundation
import SwiftUI
import UIKit

enum AuditLogExporter {

    // MARK: - PDF Summary

    static func makePDF(
        summary: ComplianceSummary,
        storeFilterName: String,
        dateRangeText: String
    ) -> URL? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: UIColor.label
            ]
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .heavy),
                .foregroundColor: UIColor.label
            ]
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.secondaryLabel
            ]

            var y: CGFloat = 40

            func drawText(_ text: String, attrs: [NSAttributedString.Key: Any], x: CGFloat = 40, maxWidth: CGFloat = 532) {
                let str = NSAttributedString(string: text, attributes: attrs)
                let rect = CGRect(x: x, y: y, width: maxWidth, height: 500)
                str.draw(in: rect)
                let height = str.boundingRect(with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                                               options: [.usesLineFragmentOrigin], context: nil).height
                y += height + 6
            }

            drawText("Audit & Compliance Report", attrs: titleAttrs)
            drawText("Store: \(storeFilterName)  •  Period: \(dateRangeText)", attrs: bodyAttrs)
            y += 12

            drawText("Key Performance Indicators", attrs: attrs)
            drawText("Compliance Score: \(summary.complianceScore)  (\(summary.complianceRating.rawValue))", attrs: bodyAttrs)
            drawText("Audit Health Score: \(summary.auditHealthScore)  (\(summary.auditHealthRating.rawValue))", attrs: bodyAttrs)
            drawText("Stores At Risk: \(summary.storesAtRiskCount)", attrs: bodyAttrs)
            drawText("Critical Exceptions: \(summary.criticalExceptionsCount)", attrs: bodyAttrs)
            drawText("Inventory Accuracy: \(String(format: "%.1f%%", summary.inventoryAccuracy))", attrs: bodyAttrs)
            y += 12

            drawText("Open Exceptions by Type", attrs: attrs)
            for ex in summary.exceptionCounts {
                drawText("  \(ex.title): \(ex.count) open  (Δ \(ex.weeklyDelta > 0 ? "+" : "")\(ex.weeklyDelta) this week)", attrs: bodyAttrs)
            }
        }

        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("AuditReport_\(Int(Date().timeIntervalSince1970)).pdf")
        try? data.write(to: url)
        return url
    }

    // MARK: - Exceptions CSV

    static func makeExceptionsCSV(
        exceptions: [AInventoryException],
        stores: [UUID: AdminStore]
    ) -> URL? {
        var rows = ["ID,Type,Priority,Status,Store,Created At,Resolved At"]
        let fmt = ISO8601DateFormatter()
        for ex in exceptions.sorted(by: { $0.createdAt > $1.createdAt }) {
            let storeName = ex.storeId.flatMap { stores[$0]?.name } ?? "N/A"
            let resolved  = ex.resolvedAt.map { fmt.string(from: $0) } ?? ""
            rows.append([
                ex.id.uuidString,
                ex.exceptionType,
                ex.priority,
                ex.status,
                storeName,
                fmt.string(from: ex.createdAt),
                resolved
            ].joined(separator: ","))
        }
        return write(csv: rows, named: "Exceptions")
    }

    // MARK: - Compliance Scores CSV

    static func makeComplianceCSV(
        scores: [AHealthScore],
        stores: [UUID: AdminStore]
    ) -> URL? {
        var rows = ["Store,Overall,Sales,Inventory,Customer,Generated At"]
        let fmt = ISO8601DateFormatter()
        for s in scores.sorted(by: { $0.generatedAt > $1.generatedAt }) {
            let storeName = stores[s.storeId]?.name ?? s.storeId.uuidString
            rows.append([
                storeName,
                String(format: "%.1f", s.overallScore),
                String(format: "%.1f", s.salesScore),
                String(format: "%.1f", s.inventoryScore),
                String(format: "%.1f", s.customerScore),
                fmt.string(from: s.generatedAt)
            ].joined(separator: ","))
        }
        return write(csv: rows, named: "ComplianceScores")
    }

    // MARK: - Private helper

    private static func write(csv rows: [String], named name: String) -> URL? {
        let content = rows.joined(separator: "\n")
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("\(name)_\(Int(Date().timeIntervalSince1970)).csv")
        try? content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
