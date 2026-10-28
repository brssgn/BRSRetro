import SwiftUI

/// Shared timeline handling so every animation behaves the same way.
///
/// - Pauses under Reduce Motion, leaving a still frame in place.
/// - Pauses while the scene is in the background.
/// - Caps the frame rate to ``SwiftUI/EnvironmentValues/retroMaxFrameRate``.
/// - Keeps its time origin in `@State`, so a parent re-rendering the view
///   does not reset the animation phase.
struct RetroTimeline<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.retroMaxFrameRate) private var maxFrameRate

    @State private var start = Date()
    private let content: (TimeInterval) -> Content

    /// - Parameter content: Receives the seconds elapsed since the view appeared.
    init(@ViewBuilder content: @escaping (TimeInterval) -> Content) {
        self.content = content
    }

    var body: some View {
        let interval: TimeInterval? = maxFrameRate > 0 && maxFrameRate.isFinite ? 1 / maxFrameRate : nil
        TimelineView(.animation(minimumInterval: interval, paused: reduceMotion || scenePhase == .background)) { context in
            content(context.date.timeIntervalSince(start))
        }
    }
}

/// A tiny deterministic random number generator so simulations are
/// reproducible in tests and previews.
struct RetroRandom: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        // xorshift64*
        state ^= state >> 12
        state ^= state << 25
        state ^= state >> 27
        return state &* 0x2545_F491_4F6C_DD1D
    }

    mutating func unit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }

    mutating func value(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + unit() * (range.upperBound - range.lowerBound)
    }
}
