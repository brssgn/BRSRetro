import CoreGraphics
import Testing
@testable import BRSRetro

@Suite("Starfield simulation")
struct StarfieldSimulationTests {
    @Test("Stars start inside the unit frustum")
    func configure() {
        let sim = StarfieldSimulation()
        sim.configure(count: 250, seed: 2)
        #expect(sim.stars.count == 250)
        for star in sim.stars {
            #expect((-1...1).contains(star.x))
            #expect((-1...1).contains(star.y))
            #expect((0...1).contains(star.z))
        }
    }

    @Test("A star on the far plane projects inside the viewport")
    func projectionFarPlane() {
        let size = CGSize(width: 400, height: 300)
        let corners = [(-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0), (0.0, 0.0)]
        for (x, y) in corners {
            let p = StarfieldSimulation.project(x, y, z: 1, in: size)
            #expect(p.x >= 0 && p.x <= size.width)
            #expect(p.y >= -50 && p.y <= size.height + 50)
        }
        let center = StarfieldSimulation.project(0, 0, z: 0.5, in: size)
        #expect(center.x == 200)
        #expect(center.y == 150)
    }

    @Test("Closer stars move outward from the center")
    func projectionMovesOutward() {
        let size = CGSize(width: 400, height: 400)
        let far = StarfieldSimulation.project(0.5, 0.5, z: 1, in: size)
        let near = StarfieldSimulation.project(0.5, 0.5, z: 0.25, in: size)
        #expect(near.x > far.x)
        #expect(near.y > far.y)
    }

    @Test("Stars approach the camera and are recycled at the far plane")
    func stepAndRecycle() {
        let sim = StarfieldSimulation()
        sim.configure(count: 100, seed: 11)
        sim.step(to: 0, velocity: 1)
        let before = sim.stars
        sim.step(to: 0.1, velocity: 1)
        for (old, new) in zip(before, sim.stars) {
            if old.z - 0.06 > StarfieldSimulation.nearPlane {
                #expect(abs(new.z - (old.z - 0.06)) < 1e-9)
            } else {
                #expect(new.z == 1)
            }
        }
        var time = 0.1
        for _ in 0..<200 {
            time += 0.1
            sim.step(to: time, velocity: 1)
            #expect(sim.stars.allSatisfy { $0.z > StarfieldSimulation.nearPlane && $0.z <= 1 })
        }
    }

    @Test("A clock that jumps backwards restarts counting instead of freezing")
    func clockReset() {
        let sim = StarfieldSimulation()
        sim.configure(count: 50, seed: 11)
        sim.step(to: 0, velocity: 1)
        sim.step(to: 30, velocity: 1)
        sim.step(to: 1, velocity: 1)
        let before = sim.stars
        sim.step(to: 1.05, velocity: 1)
        var moved = 0
        for (old, new) in zip(before, sim.stars) where new.z != 1 {
            #expect(abs(new.z - (old.z - 0.03)) < 1e-9)
            moved += 1
        }
        #expect(moved > 0)
    }

    @Test("Same seed gives the same sky")
    func deterministic() {
        let a = StarfieldSimulation()
        let b = StarfieldSimulation()
        for sim in [a, b] {
            sim.configure(count: 50, seed: 123)
            sim.step(to: 0, velocity: 1)
            sim.step(to: 0.4, velocity: 1)
        }
        #expect(a.stars == b.stars)
    }
}
