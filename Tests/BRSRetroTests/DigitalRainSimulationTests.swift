import Testing
@testable import BRSRetro

@Suite("Digital rain simulation")
struct DigitalRainSimulationTests {
    @Test("Configure builds one column per slot with the requested density")
    func configure() {
        let sim = DigitalRainSimulation()
        sim.configure(columns: 40, rows: 30, density: 1, seed: 3)
        #expect(sim.columns.count == 40)
        #expect(sim.rows == 30)
        #expect(sim.columns.allSatisfy { $0.active })

        sim.configure(columns: 40, rows: 30, density: 0, seed: 3)
        #expect(sim.columns.allSatisfy { !$0.active })
    }

    @Test("Reconfiguring with the same parameters keeps the field")
    func configureIsIdempotent() {
        let sim = DigitalRainSimulation()
        sim.configure(columns: 10, rows: 20, density: 0.5, seed: 9)
        sim.step(to: 0)
        sim.step(to: 0.5)
        let before = sim.columns
        sim.configure(columns: 10, rows: 20, density: 0.5, seed: 9)
        #expect(sim.columns == before)
    }

    @Test("Heads advance by speed times elapsed time")
    func heads_advance() {
        let sim = DigitalRainSimulation()
        sim.configure(columns: 5, rows: 100, density: 1, seed: 1)
        sim.step(to: 0)
        let before = sim.columns
        sim.step(to: 0.05)
        for (old, new) in zip(before, sim.columns) {
            #expect(new.head == old.head + old.speed * 0.05)
        }
    }

    @Test("Large time steps are clamped")
    func clampedStep() {
        let sim = DigitalRainSimulation()
        sim.configure(columns: 3, rows: 100, density: 1, seed: 1)
        sim.step(to: 0)
        let before = sim.columns
        sim.step(to: 10)
        for (old, new) in zip(before, sim.columns) {
            #expect(new.head == old.head + old.speed * 0.1)
        }
    }

    @Test("A clock that jumps backwards restarts counting instead of freezing")
    func clockReset() {
        let sim = DigitalRainSimulation()
        sim.configure(columns: 4, rows: 100, density: 1, seed: 1)
        sim.step(to: 0)
        sim.step(to: 30)
        sim.step(to: 1)          // a parent re-render reset the time origin
        let before = sim.columns
        sim.step(to: 1.05)
        for (old, new) in zip(before, sim.columns) {
            #expect(abs(new.head - (old.head + old.speed * 0.05)) < 1e-9)
        }
    }

    @Test("Columns respawn above the top once their tail leaves the bottom")
    func respawn() {
        let sim = DigitalRainSimulation()
        sim.configure(columns: 20, rows: 12, density: 1, seed: 5)
        sim.step(to: 0)
        var time = 0.0
        for _ in 0..<600 {
            time += 0.05
            sim.step(to: time)
            for column in sim.columns {
                #expect(column.head - Double(column.length) <= Double(sim.rows))
                #expect(column.length >= 4)
                #expect(column.glyphs.allSatisfy { (0..<DigitalRainSimulation.glyphs.count).contains($0) })
            }
        }
    }

    @Test("Same seed gives the same rain")
    func deterministic() {
        let a = DigitalRainSimulation()
        let b = DigitalRainSimulation()
        for sim in [a, b] {
            sim.configure(columns: 8, rows: 16, density: 0.7, seed: 77)
            sim.step(to: 0)
            sim.step(to: 0.3)
            sim.step(to: 0.6)
        }
        #expect(a.columns == b.columns)
    }
}
