//
//  ShareSheet.swift
//  Admin_RSMS
//
//  A SwiftUI view modifier that presents a UIActivityViewController when
//  a URL binding becomes non-nil, and clears it again on dismiss.
//  Usage:
//      .shareSheet(url: $viewModel.exportedFileURL)
//

import SwiftUI
import UIKit

// MARK: - UIKit wrapper

private struct ShareSheetController: UIViewControllerRepresentable {
    let url: URL
    @Binding var exportedURL: URL?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in
            exportedURL = nil
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - View modifier

private struct ShareSheetModifier: ViewModifier {
    @Binding var url: URL?

    func body(content: Content) -> some View {
        content
            .sheet(item: Binding(
                get: { url.map(IdentifiableURL.init) },
                set: { if $0 == nil { url = nil } }
            )) { wrapper in
                ShareSheetController(url: wrapper.url, exportedURL: $url)
                    .ignoresSafeArea()
            }
    }
}

// MARK: - Identifiable URL wrapper

private struct IdentifiableURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

// MARK: - Extension

extension View {
    /// Presents a share sheet when `url` is non-nil, clearing it on dismiss.
    func shareSheet(url: Binding<URL?>) -> some View {
        modifier(ShareSheetModifier(url: url))
    }
}
