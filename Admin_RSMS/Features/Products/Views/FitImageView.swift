//
//  FitImageView.swift
//  Admin_RSMS
//
//  Created by Yatharth Mishra on 02/07/26.
//


import SwiftUI

/// Renders a remote image scaled with `.fit` so the *entire* image is always
/// visible — vertical shots, horizontal shots, whatever the source aspect
/// ratio, nothing gets cropped. Sits on a soft tinted backdrop so it never
/// looks like empty letterboxing, just a deliberate frame around the photo.
struct FitImageView: View {
    let url: URL?
    let backdropColor: Color
    var placeholderIcon: String = "photo.on.rectangle.angled"

    var body: some View {
        ZStack {
            backdropColor

            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(6)
                    case .empty:
                        ProgressView()
                            .tint(.secondary)
                    case .failure:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        Image(systemName: placeholderIcon)
            .font(.system(size: 28))
            .foregroundStyle(.secondary)
    }
}