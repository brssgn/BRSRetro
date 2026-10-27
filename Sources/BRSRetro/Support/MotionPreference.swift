import SwiftUI

/// Shared timeline handling so every animation honors Reduce Motion the same way.
///
/// When the user has Reduce Motion enabled the timeline is paused, which
/// leaves a still frame of the animation in place rather than removing it.
struct RetroTimeline<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let start: Date
    private let content: (TimeInterval) -> Content

    /// - Parameter content: Receives the seconds elapsed since the view appeared.
    init(@ViewBuilder content: @escaping (TimeInterval) -> Content) {
        self.start = Date()
        self.content = content
    }

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { context in
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
