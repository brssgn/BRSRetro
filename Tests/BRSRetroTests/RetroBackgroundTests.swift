import SwiftUI
import Testing
@testable import BRSRetro

@Suite("Public surface")
struct RetroBackgroundTests {
    @Test("Every background has a title and an inspiration")
    func metadata() {
        #expect(RetroBackground.allCases.count == 4)
        for background in RetroBackground.allCases {
            #expect(!background.title.isEmpty)
            #expect(!background.inspiration.isEmpty)
            #expect(background.id == background.rawValue)
        }
    }

    @Test("CRT presets stay within range")
    func crtPresets() {
        for preset in [CRTSettings.default, .subtle, .heavy] {
            for value in [preset.curvature, preset.scanlines, preset.vignette, preset.noise, preset.flicker, preset.rollingBar] {
                #expect((0...1).contains(value))
            }
            #expect(preset.chroma >= 0)
            #expect(preset.scanlinePitch >= 1)
        }
    }

    @Test("The seeded generator is deterministic and non-degenerate")
    func random() {
        var a = RetroRandom(seed: 99)
        var b = RetroRandom(seed: 99)
        var values: Set<UInt64> = []
        for _ in 0..<100 {
            let v = a.next()
            #expect(v == b.next())
            values.insert(v)
        }
        #expect(values.count == 100)
        var zero = RetroRandom(seed: 0)
        #expect(zero.next() != 0)
        for _ in 0..<1000 {
            let unit = zero.unit()
            #expect(unit >= 0 && unit < 1)
        }
    }

    @MainActor
    @Test("Views can be constructed with defaults")
    func construct() {
        _ = SynthwaveGridView()
        _ = DigitalRainView()
        _ = HyperspaceView()
        _ = PlasmaView()
        _ = CRTOverlayView()
        _ = Text("hi").crtOverlay()
        _ = Text("hi").retroBackground(.plasma)
    }
}
