//
//  AuditDesign.swift
//  Admin_RSMS
//
//  Shared, minimal building blocks for the Audit & Compliance screen.
//  One consistent, quiet visual language: a single accent color, one
//  type scale, no decorative repetition. Every card below reuses
//  `SectionHeader` / `MetricLabel` instead of hand-rolling its own —
//  that alone removes most of the visual inconsistency that made the
//  old screen feel busy.
//

import SwiftUI

/// Standard header row used at the top of every card: icon + title on
/// the left, one small piece of context on the right. Nothing else.
struct SectionHeader: View {
    let icon: String
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.rsmsBlue)
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Small caps label used above every metric number, so KPI cards read
/// identically instead of each inventing its own label treatment.
struct MetricLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .tracking(0.4)
    }
}

/// A plain empty-state row — same shape everywhere a section has nothing to show.
struct AuditEmptyState: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 18)
    }
}
