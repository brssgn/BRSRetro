import SwiftUI

/// Strengths for the CRT / VHS treatment. Every value is `0` (off) to `1`
/// (strong) except ``chroma`` and ``scanlinePitch``, which are in points.
public struct CRTSettings: Sendable, Equatable {
    /// Barrel distortion of the picture toward the corners.
    public var curvature: Double
    /// Horizontal RGB channel separation, in points.
    public var chroma: Double
    /// Darkness of the scanlines.
    public var scanlines: Double
    /// Distance between scanlines, in points.
    public var scanlinePitch: Double
    /// Darkening toward the edges.
    public var vignette: Double
    /// Static grain.
    public var noise: Double
    /// Brightness flicker.
    public var flicker: Double
    /// The slow vertical tracking bar of a worn tape.
    public var rollingBar: Double

    public init(
        curvature: Double = 0.6,
        chroma: Double = 1.2,
        scanlines: Double = 0.6,
        scanlinePitch: Double = 3,
        vignette: Double = 0.7,
        noise: Double = 0.25,
        flicker: Double = 0.3,
        rollingBar: Double = 0.4
    ) {
        self.curvature = curvature
        self.chroma = chroma
        self.scanlines = scanlines
        self.scanlinePitch = scanlinePitch
        self.vignette = vignette
        self.noise = noise
        self.flicker = flicker
        self.rollingBar = rollingBar
    }

    /// The full worn-tape look.
    public static let `default` = CRTSettings()
    /// Scanlines and a touch of vignette, no distortion. Safe for text-heavy screens.
    public static let subtle = CRTSettings(curvature: 0, chroma: 0.4, scanlines: 0.35, vignette: 0.4, noise: 0.1, flicker: 0, rollingBar: 0)
    /// Everything turned up. The tape has been through a lot.
    public static let heavy = CRTSettings(curvature: 1, chroma: 2.5, scanlines: 0.8, vignette: 0.9, noise: 0.5, flicker: 0.6, rollingBar: 1)
}

extension View {
    /// Runs this view through an old CRT television and a tired VHS deck.
    ///
    /// Inspired by Stranger Things title cards and every tape you rented in
    /// 1986. The whole treatment is a single Metal `layerEffect`.
    public func crtOverlay(_ settings: CRTSettings = .default) -> some View {
        modifier(CRTModifier(settings: settings))
    }
}

struct CRTModifier: ViewModifier {
    let settings: CRTSettings

    func body(content: Content) -> some View {
        RetroTimeline { elapsed in
            content
                .layerEffect(
                    RetroShaders.library.crt(
                        .boundingRect,
                        .float(Float(elapsed)),
                        .float(Float(settings.curvature)),
                        .float(Float(settings.chroma)),
                        .float(Float(settings.scanlines)),
                        .float(Float(settings.scanlinePitch)),
                        .float(Float(settings.vignette)),
                        .float(Float(settings.noise)),
                        .float(Float(settings.flicker)),
                        .float(Float(settings.rollingBar))
                    ),
                    maxSampleOffset: CGSize(width: settings.chroma * 3 + 2, height: 2)
                )
        }
    }
}

/// A transparent layer of scanlines, vignette and flicker to stack over any
/// background. Unlike ``SwiftUI/View/crtOverlay(_:)`` it does not sample the
/// content beneath it, so it is nearly free.
public struct CRTOverlayView: View {
    public var settings: CRTSettings

    public init(_ settings: CRTSettings = .subtle) {
        self.settings = settings
    }

    public var body: some View {
        RetroTimeline { elapsed in
            Rectangle()
                .fill(.white)
                .colorEffect(
                    RetroShaders.library.scanlineOverlay(
                        .boundingRect,
                        .float(Float(elapsed)),
                        .float(Float(settings.scanlines)),
                        .float(Float(settings.scanlinePitch)),
                        .float(Float(settings.vignette)),
                        .float(Float(settings.flicker))
                    )
                )
        }
        .allowsHitTesting(false)
    }
}

#Preview("CRT over synthwave") {
    SynthwaveGridView()
        .crtOverlay()
        .ignoresSafeArea()
}

#Preview("Scanline overlay over plasma") {
    ZStack {
        PlasmaView()
        CRTOverlayView()
    }
    .ignoresSafeArea()
}
