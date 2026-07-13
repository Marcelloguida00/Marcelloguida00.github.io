import SwiftUI
import Charts

/// Grafico di inerzia: differenziale punti cumulativo (sopra lo zero = in
/// vantaggio io/noi). Le linee tratteggiate segnano la fine dei set.
struct MomentumChart: View {
    let timeline: [Int]
    let setBreaks: [Int]

    private var diffs: [Int] {
        var d = 0
        return [0] + timeline.map { t in d += t == 0 ? 1 : -1; return d }
    }

    var body: some View {
        let data = diffs
        Chart {
            RuleMark(y: .value("Pari", 0))
                .foregroundStyle(.gray.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1))

            ForEach(setBreaks, id: \.self) { b in
                RuleMark(x: .value("Set", b))
                    .foregroundStyle(.yellow.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }

            ForEach(Array(data.enumerated()), id: \.offset) { i, d in
                AreaMark(x: .value("Punto", i), y: .value("Inerzia", d))
                    .foregroundStyle(.linearGradient(
                        colors: [.cyan.opacity(0.35), .orange.opacity(0.35)],
                        startPoint: .top, endPoint: .bottom))
                    .interpolationMethod(.monotone)
                LineMark(x: .value("Punto", i), y: .value("Inerzia", d))
                    .foregroundStyle(.cyan)
                    .interpolationMethod(.monotone)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) {
                AxisValueLabel().font(.system(size: 9))
            }
        }
        .accessibilityLabel("Grafico inerzia: differenziale punti nel corso del match")
    }

    /// Serie più lunga di punti consecutivi per il team indicato.
    static func longestStreak(_ timeline: [Int], team: Int) -> Int {
        var best = 0, run = 0
        for t in timeline {
            run = t == team ? run + 1 : 0
            best = max(best, run)
        }
        return best
    }
}
