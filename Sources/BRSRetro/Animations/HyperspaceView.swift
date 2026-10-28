import SwiftUI

/// Stars streaking outward from the center as if the ship just made the jump.
///
/// Inspired by the lightspeed jump in Star Wars and the starfield screensaver
/// that shipped on every beige PC. Drawn with `Canvas`; the projection math is
/// in ``StarfieldSimulation`` so it can be tested.
public struct HyperspaceView: View {
    public var starCount: Int
    /// Playback speed multiplier.
    public var speed: Double
    /// Length of the streaks relative to the default. `0` draws dots.
    public var streakLength: Double
    /// Seconds over which the field accelerates from a crawl to full speed
    /// after appearing. `0` starts at full speed.
    public var warpIn: Double
    public var tint: Color
    public var backgroundColor: Color
    public var seed: UInt64

    @State private var simulation = StarfieldSimulation()

    public init(
        starCount: Int = 400,
        speed: Double = 1,
        streakLength: Double = 1,
        warpIn: Double = 2.5,
        tint: Color = .white,
        backgroundColor: Color = .black,
        seed: UInt64 = 42
    ) {
        self.starCount = starCount
        self.speed = speed
        self.streakLength = streakLength
        self.warpIn = warpIn
        self.tint = tint
        self.backgroundColor = backgroundColor
        self.seed = seed
    }

    public var body: some View {
        RetroTimeline { elapsed in
            Canvas(rendersAsynchronously: false) { context, size in
                simulation.configure(count: starCount, seed: seed)
                let ramp = warpIn > 0 ? min(elapsed / warpIn, 1) : 1
                let velocity = speed * (0.08 + 0.92 * ramp * ramp)
                simulation.step(to: elapsed, velocity: velocity)
                draw(simulation, in: &context, size: size, streak: streakLength * (0.2 + ramp))
            }
            .background(backgroundColor)
        }
        .allowsHitTesting(false)
    }

    private func draw(_ sim: StarfieldSimulation, in context: inout GraphicsContext, size: CGSize, streak: Double) {
        for star in sim.stars {
            let end = StarfieldSimulation.project(star.x, star.y, z: star.z, in: size)
            let tailZ = min(star.z + 0.06 * streak, 1)
            let start = StarfieldSimulation.project(star.x, star.y, z: tailZ, in: size)
            let brightness = pow(1 - star.z, 1.5)
            guard brightness > 0.01 else { continue }

            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            context.stroke(
                path,
                with: .color(tint.opacity(0.3 + 0.7 * brightness)),
                style: StrokeStyle(lineWidth: 0.5 + 2.5 * brightness, lineCap: .round)
            )
        }
    }
}

struct Star: Equatable {
    /// Lateral position in the range `-1...1`.
    var x: Double
    var y: Double
    /// Depth from `0` (at the camera) to `1` (far plane).
    var z: Double
}

/// Stars in a unit frustum moving toward the camera.
final class StarfieldSimulation {
    private(set) var stars: [Star] = []
    private(set) var lastTime: TimeInterval?
    private var rng = RetroRandom(seed: 1)
    private var configuredKey: (Int, UInt64)?

    /// Depth at which a star has passed the camera and is recycled.
    static let nearPlane = 0.02

    init() {}

    func configure(count: Int, seed: UInt64) {
        let key = (count, seed)
        if let configuredKey, configuredKey == key { return }
        configuredKey = key
        rng = RetroRandom(seed: seed)
        lastTime = nil
        stars = (0..<max(count, 0)).map { _ in
            Star(x: rng.value(in: -1...1), y: rng.value(in: -1...1), z: rng.unit())
        }
    }

    /// Moves every star toward the camera by `velocity × dt` in depth units.
    func step(to time: TimeInterval, velocity: Double) {
        guard let previous = lastTime, time >= previous else {
            // First frame, or the clock was reset: start counting from here.
            lastTime = time
            return
        }
        let dt = min(time - previous, 0.1)
        lastTime = time
        guard dt > 0 else { return }

        for index in stars.indices {
            stars[index].z -= velocity * 0.6 * dt
            if stars[index].z <= Self.nearPlane {
                stars[index] = Star(x: rng.value(in: -1...1), y: rng.value(in: -1...1), z: 1)
            }
        }
    }

    /// Perspective projection into a rectangle. A star at `z == 1` lands at its
    /// lateral position scaled to the half-size; smaller `z` pushes it outward.
    static func project(_ x: Double, _ y: Double, z: Double, in size: CGSize) -> CGPoint {
        let half = max(size.width, size.height) / 2
        let depth = max(z, 0.001)
        return CGPoint(
            x: size.width / 2 + x / depth * half,
            y: size.height / 2 + y / depth * half
        )
    }
}

#Preview("Hyperspace") {
    HyperspaceView()
        .ignoresSafeArea()
}

#Preview("Hyperspace, cyan dots") {
    HyperspaceView(starCount: 800, speed: 0.4, streakLength: 0, warpIn: 0, tint: RetroPalette.neonCyan)
        .ignoresSafeArea()
}
