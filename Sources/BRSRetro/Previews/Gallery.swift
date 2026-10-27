import SwiftUI

#if DEBUG
/// Pages through every built-in background with a title card, the way the
/// README screenshots were taken.
struct RetroGallery: View {
    var body: some View {
        TabView {
            ForEach(RetroBackground.allCases) { background in
                card(background.title, background.inspiration) {
                    RetroBackgroundView(background)
                }
            }
            card("CRT Overlay", "Stranger Things · worn VHS") {
                SynthwaveGridView().crtOverlay()
            }
        }
        #if os(iOS) || os(tvOS) || os(visionOS)
        .tabViewStyle(.page)
        #endif
        .ignoresSafeArea()
    }

    private func card(_ title: String, _ subtitle: String, @ViewBuilder content: () -> some View) -> some View {
        content()
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.title.bold())
                    Text(subtitle).font(.subheadline)
                }
                .foregroundStyle(.white)
                .padding(24)
                .shadow(radius: 8)
            }
    }
}

#Preview("Gallery") {
    RetroGallery()
}
#endif
