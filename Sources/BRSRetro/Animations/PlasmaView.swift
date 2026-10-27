import SwiftUI

/// Swirling sine-wave color fields, the way every Amiga and C64 demo opened.
///
/// Rendered in a Metal shader. Pass your own three colors to re-theme it.
public struct PlasmaView: View {
    /// Playback speed multiplier.
    public var speed: Double
    /// How many sine periods fit across the height. Lower is bigger blobs.
    public var scale: Double
    public var colors: (Color, Color, Color)

    public init(
        speed: Double = 1,
        scale: Double = 8,
        colors: (Color, Color, Color) = (RetroPalette.hotPink, RetroPalette.deepPurple, RetroPalette.neonCyan)
    ) {
        self.speed = speed
        self.scale = scale
        self.colors = colors
    }

    public var body: some View {
        RetroTimeline { elapsed in
            Rectangle()
                .fill(.black)
                .colorEffect(
                    RetroShaders.library.plasma(
                        .boundingRect,
                        .float(Float(elapsed * speed)),
                        .float(Float(scale)),
                        .color(colors.0),
                        .color(colors.1),
                        .color(colors.2)
                    )
                )
        }
        .allowsHitTesting(false)
    }
}

#Preview("Plasma") {
    PlasmaView()
        .ignoresSafeArea()
}

#Preview("Plasma, ocean") {
    PlasmaView(scale: 5, colors: (RetroPalette.midnight, RetroPalette.neonCyan, RetroPalette.matrixGreen))
        .ignoresSafeArea()
}
