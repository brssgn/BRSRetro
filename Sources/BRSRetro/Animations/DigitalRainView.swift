import SwiftUI

/// Columns of glyphs falling down the screen with bright heads and fading
/// tails. You know the one.
///
/// Drawn with `Canvas`. The simulation lives in ``DigitalRainSimulation`` so
/// its behavior can be tested without rendering.
public struct DigitalRainView: View {
    public var fontSize: Double
    /// Playback speed multiplier.
    public var speed: Double
    /// Fraction of available columns that carry rain, `0` to `1`.
    public var density: Double
    public var color: Color
    public var headColor: Color
    public var backgroundColor: Color
    public var seed: UInt64

    @State private var simulation = DigitalRainSimulation()

    public init(
        fontSize: Double = 18,
        speed: Double = 1,
        density: Double = 0.8,
        color: Color = RetroPalette.matrixGreen,
        headColor: Color = RetroPalette.phosphor,
        backgroundColor: Color = .black,
        seed: UInt64 = 7
    ) {
        self.fontSize = fontSize
        self.speed = speed
        self.density = density
        self.color = color
        self.headColor = headColor
        self.backgroundColor = backgroundColor
        self.seed = seed
    }

    public var body: some View {
        RetroTimeline { elapsed in
            Canvas(rendersAsynchronously: false) { context, size in
                let cell = CGSize(width: fontSize * 0.95, height: fontSize * 1.15)
                let columns = Int(ceil(size.width / cell.width))
                let rows = Int(ceil(size.height / cell.height)) + 1
                simulation.configure(columns: columns, rows: rows, density: density, seed: seed)
                simulation.step(to: elapsed * speed)
                draw(simulation, in: &context, cell: cell, rows: rows)
            } symbols: {
                // One white glyph per symbol. SwiftUI rasterizes these once and
                // caches them; the draw loop only tints and places them.
                let font = Font.system(size: fontSize, design: .monospaced).weight(.medium)
                ForEach(0..<DigitalRainSimulation.glyphs.count, id: \.self) { index in
                    Text(String(DigitalRainSimulation.glyphs[index]))
                        .font(font)
                        .foregroundStyle(.white)
                        .tag(index)
                }
            }
            .background(backgroundColor)
        }
        .allowsHitTesting(false)
    }

    private func draw(_ sim: DigitalRainSimulation, in context: inout GraphicsContext, cell: CGSize, rows: Int) {
        let glyphs = (0..<DigitalRainSimulation.glyphs.count).map { context.resolveSymbol(id: $0) }

        for (columnIndex, column) in sim.columns.enumerated() where column.active {
            let head = Int(column.head.rounded(.down))
            let first = max(0, head - column.length)
            let last = min(rows - 1, head)
            guard first <= last else { continue }
            let x = (Double(columnIndex) + 0.5) * cell.width

            for row in first...last {
                let age = head - row
                let fade = 1 - Double(age) / Double(column.length)
                let glyphIndex = column.glyphs[row % column.glyphs.count]
                let point = CGPoint(x: x, y: (Double(row) + 0.5) * cell.height)

                guard let glyph = glyphs[glyphIndex] else { continue }

                var layer = context
                if age == 0 {
                    layer.addFilter(.colorMultiply(headColor))
                    layer.addFilter(.shadow(color: headColor.opacity(0.9), radius: fontSize * 0.5))
                } else {
                    layer.addFilter(.colorMultiply(color))
                    layer.opacity = pow(fade, 1.5)
                }
                layer.draw(glyph, at: point)
            }
        }
    }
}

/// One falling column of glyphs.
struct RainColumn: Equatable {
    /// Row of the brightest glyph, fractional while it travels.
    var head: Double
    /// Rows per second.
    var speed: Double
    /// Number of rows that stay lit behind the head.
    var length: Int
    /// Glyph index for each row, mutated occasionally while the column falls.
    var glyphs: [Int]
    var active: Bool
}

/// The rain without the pixels. Columns advance by `speed × dt`, respawn above
/// the top edge once their tail has left the bottom, and swap glyphs at random.
final class DigitalRainSimulation {
    static let glyphs: [Character] = Array(
        "ﾊﾐﾋｰｳｼﾅﾓﾆｻﾜﾂｵﾘｱﾎﾃﾏｹﾒｴｶｷﾑﾕﾗｾﾈｽﾀﾇﾍ0123456789Z:・.\"=*+-<>¦|ç"
    )

    private(set) var columns: [RainColumn] = []
    private(set) var rows = 0
    private(set) var lastTime: TimeInterval?
    private var rng = RetroRandom(seed: 1)
    private var configuredKey: (Int, Int, Double, UInt64)?

    init() {}

    /// Resets the field if the grid or parameters changed. Cheap otherwise.
    func configure(columns: Int, rows: Int, density: Double, seed: UInt64) {
        let key = (columns, rows, density, seed)
        if let configuredKey, configuredKey == key { return }
        configuredKey = key
        self.rows = rows
        rng = RetroRandom(seed: seed)
        lastTime = nil
        self.columns = (0..<max(columns, 0)).map { _ in
            var column = makeColumn(rows: rows)
            column.active = rng.unit() < density
            // Scatter the initial heads so the first frame already looks busy.
            column.head = rng.value(in: -Double(rows) * 0.5...Double(rows))
            return column
        }
    }

    /// Advances the simulation to `time` seconds. Steps larger than 100 ms are
    /// clamped so a backgrounded app does not jump when it resumes.
    func step(to time: TimeInterval) {
        guard let previous = lastTime, time >= previous else {
            // First frame, or the clock was reset: start counting from here.
            lastTime = time
            return
        }
        let dt = min(time - previous, 0.1)
        lastTime = time
        guard dt > 0 else { return }

        for index in columns.indices where columns[index].active {
            columns[index].head += columns[index].speed * dt
            if columns[index].head - Double(columns[index].length) > Double(rows) {
                let active = columns[index].active
                columns[index] = makeColumn(rows: rows)
                columns[index].active = active
            }
            // Mutate roughly 4% of visible glyphs per 100 ms.
            let swaps = Int(Double(columns[index].length) * 0.4 * dt + rng.unit())
            for _ in 0..<swaps {
                let slot = Int(rng.unit() * Double(columns[index].glyphs.count))
                columns[index].glyphs[slot] = Int(rng.unit() * Double(Self.glyphs.count))
            }
        }
    }

    private func makeColumn(rows: Int) -> RainColumn {
        let length = Int(rng.value(in: 6...Double(max(rows, 8)) * 0.8))
        return RainColumn(
            head: rng.value(in: -Double(length)...0) - Double(rows) * 0.4 * rng.unit(),
            speed: rng.value(in: 6...22),
            length: max(length, 4),
            glyphs: (0..<max(rows, 1)).map { _ in Int(rng.unit() * Double(Self.glyphs.count)) },
            active: true
        )
    }
}

#Preview("Digital Rain") {
    DigitalRainView()
        .ignoresSafeArea()
}

#Preview("Digital Rain, amber terminal") {
    DigitalRainView(fontSize: 14, speed: 0.7, color: RetroPalette.sunsetOrange, headColor: RetroPalette.warmYellow)
        .ignoresSafeArea()
}
