//
//  GlassChipRow.swift
//  Admin_RSMS
//
//  Created by Yatharth Mishra on 04/07/26.
//


//
//  LiquidGlass.swift
//  Admin_RSMS
//
//  Small set of reusable helpers around iOS 26's Liquid Glass material
//  (`glassEffect`, `GlassEffectContainer`, `.glass` / `.glassProminent`
//  button styles). Centralised here so every screen — not just Audit
//  Logs — can opt into the same look with one modifier.
//
//  Requires iOS 26+ (already the project's minimum deployment target,
//  see SRS §2.3 Technical Specifications).
//

import SwiftUI

extension View {

    /// Wraps the view in a rounded Liquid Glass surface.
    /// Use for cards, headers, filter bars — anything that used to be a
    /// flat `.background(Color(...))` card.
    func glassCard(cornerRadius: CGFloat = 20, tint: Color? = nil) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return Group {
            if let tint {
                self.glassEffect(.regular.tint(tint.opacity(0.35)), in: shape)
            } else {
                self.glassEffect(.regular, in: shape)
            }
        }
        // Glass alone reads as nearly-flat on light backgrounds; the
        // shadow is what actually lifts each card off the page and
        // separates it from its neighbours.
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
    }

    /// A pill-shaped glass chip, used for filter chips and badges.
    func glassChip(tint: Color? = nil, isInteractive: Bool = true) -> some View {
        let shape = Capsule(style: .continuous)
        return Group {
            if let tint {
                self.glassEffect(
                    isInteractive ? .regular.tint(tint.opacity(0.35)).interactive() : .regular.tint(tint.opacity(0.35)),
                    in: shape
                )
            } else {
                self.glassEffect(isInteractive ? .regular.interactive() : .regular, in: shape)
            }
        }
    }
}

/// Convenience container for grouping several glass elements (e.g. the
/// filter chip row) so Liquid Glass can morph/merge them smoothly instead
/// of rendering each as an isolated pane.
///
/// IMPORTANT: only use this for elements that *should* visually blend
/// together at close range (pill-shaped chips, segmented controls).
/// Do NOT wrap grids/rows of full-size rectangular cards in this —
/// GlassEffectContainer actively merges nearby glass shapes into one
/// continuous surface once they're within `spacing` of each other, and
/// flat-edged cards sitting ~16pt apart will fuse into a single blob
/// with no visible boundaries between them. Rectangular cards should
/// each just call `.glassCard()` standalone (already gives them their
/// own shadow/elevation) with no shared container.
struct GlassChipRow<Content: View>: View {
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                content()
            }
        }
    }
}

enum RSMSGlassButtonStyle {
    /// Primary call to action (e.g. "Export CSV", the "+" FAB).
    static func prominent() -> some PrimitiveButtonStyle { .glassProminent }
    /// Secondary action (e.g. "Export PDF").
    static func standard() -> some PrimitiveButtonStyle { .glass }
}