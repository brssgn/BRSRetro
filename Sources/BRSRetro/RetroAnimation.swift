// BRSRetro
//
// Retro-vibe, pop-culture inspired background animations for SwiftUI.
//
// Every animation is a plain `View` that fills whatever space it is given.
// Drop one behind your content with `.retroBackground(.synthwaveGrid)` or
// use the views directly for full control over their parameters.

import SwiftUI

/// Neon colors shared by the built-in animations. Use them to keep custom
/// tweaks on-palette, or ignore them entirely.
public enum RetroPalette {
    public static let midnight = Color(red: 0.04, green: 0.02, blue: 0.10)
    public static let deepPurple = Color(red: 0.16, green: 0.03, blue: 0.32)
    public static let electricPurple = Color(red: 0.45, green: 0.10, blue: 0.75)
    public static let hotPink = Color(red: 1.00, green: 0.16, blue: 0.62)
    public static let neonCyan = Color(red: 0.10, green: 0.95, blue: 1.00)
    public static let sunsetOrange = Color(red: 1.00, green: 0.45, blue: 0.15)
    public static let warmYellow = Color(red: 1.00, green: 0.90, blue: 0.35)
    public static let matrixGreen = Color(red: 0.20, green: 1.00, blue: 0.40)
    public static let phosphor = Color(red: 0.75, green: 1.00, blue: 0.80)
}

/// The built-in full-screen backgrounds, for the cases where you want a
/// one-liner rather than configuring a view yourself.
public enum RetroBackground: String, CaseIterable, Identifiable, Sendable {
    /// Neon perspective grid scrolling toward a striped sun. Tron, Drive, Outrun.
    case synthwaveGrid
    /// Falling columns of glyphs with bright heads. The Matrix.
    case digitalRain
    /// Stars streaking outward from the center. The jump to lightspeed.
    case hyperspace
    /// Swirling sine-wave colors. Amiga and C64 demoscene.
    case plasma

    public var id: String { rawValue }

    /// Human readable name, handy for galleries and pickers.
    public var title: String {
        switch self {
        case .synthwaveGrid: "Synthwave Grid"
        case .digitalRain: "Digital Rain"
        case .hyperspace: "Hyperspace"
        case .plasma: "Plasma"
        }
    }

    /// The pop-culture reference the animation nods to.
    public var inspiration: String {
        switch self {
        case .synthwaveGrid: "Tron · Drive · Outrun"
        case .digitalRain: "The Matrix"
        case .hyperspace: "Star Wars · classic screensavers"
        case .plasma: "Amiga / C64 demoscene"
        }
    }
}

/// Renders a ``RetroBackground`` with its default parameters.
public struct RetroBackgroundView: View {
    private let background: RetroBackground

    public init(_ background: RetroBackground) {
        self.background = background
    }

    public var body: some View {
        switch background {
        case .synthwaveGrid: SynthwaveGridView()
        case .digitalRain: DigitalRainView()
        case .hyperspace: HyperspaceView()
        case .plasma: PlasmaView()
        }
    }
}

extension View {
    /// Places a built-in retro animation behind this view. The view expands to
    /// fill the space it is offered and the animation extends under the safe
    /// area, so a bare `Text` ends up centered on a full-screen background.
    public func retroBackground(_ background: RetroBackground) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RetroBackgroundView(background)
                    .ignoresSafeArea()
            }
    }
}
