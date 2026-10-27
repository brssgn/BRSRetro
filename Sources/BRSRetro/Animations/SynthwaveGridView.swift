import SwiftUI

/// A neon perspective grid rolling toward a striped sun on the horizon.
///
/// Inspired by Tron, Drive, Kung Fury and the Outrun aesthetic. Rendered
/// entirely in a Metal shader, so it is cheap even at full screen.
public struct SynthwaveGridView: View {
    /// Playback speed multiplier. `1` is the default pace, `0` freezes the grid.
    public var speed: Double
    /// Vertical position of the horizon as a fraction of the height, `0` is the top.
    public var horizon: Double
    public var gridColor: Color
    public var skyTop: Color
    public var skyBottom: Color
    public var sunTop: Color
    public var sunBottom: Color
    public var groundColor: Color

    public init(
        speed: Double = 1,
        horizon: Double = 0.58,
        gridColor: Color = RetroPalette.hotPink,
        skyTop: Color = RetroPalette.midnight,
        skyBottom: Color = RetroPalette.electricPurple,
        sunTop: Color = RetroPalette.warmYellow,
        sunBottom: Color = RetroPalette.hotPink,
        groundColor: Color = RetroPalette.midnight
    ) {
        self.speed = speed
        self.horizon = horizon
        self.gridColor = gridColor
        self.skyTop = skyTop
        self.skyBottom = skyBottom
        self.sunTop = sunTop
        self.sunBottom = sunBottom
        self.groundColor = groundColor
    }

    public var body: some View {
        RetroTimeline { elapsed in
            Rectangle()
                .fill(.black)
                .colorEffect(
                    RetroShaders.library.synthwaveGrid(
                        .boundingRect,
                        .float(Float(elapsed * speed)),
                        .float(Float(horizon)),
                        .color(skyTop),
                        .color(skyBottom),
                        .color(sunTop),
                        .color(sunBottom),
                        .color(gridColor),
                        .color(groundColor)
                    )
                )
        }
        .allowsHitTesting(false)
    }
}

#Preview("Synthwave Grid") {
    SynthwaveGridView()
        .ignoresSafeArea()
}

#Preview("Synthwave Grid, cyan") {
    SynthwaveGridView(gridColor: RetroPalette.neonCyan, sunBottom: RetroPalette.sunsetOrange)
        .ignoresSafeArea()
}
