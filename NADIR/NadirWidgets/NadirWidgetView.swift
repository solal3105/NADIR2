import SwiftUI
import WidgetKit

/// Petit et moyen : lieu, alarme armée, la courbe, le verdict.
struct NadirWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: NadirEntry

    private var isSmall: Bool { family == .systemSmall }

    var body: some View {
        let analysis = entry.analysis
        VStack(alignment: .leading, spacing: isSmall ? 6 : 8) {
            header(analysis)
            WidgetChart(analysis: analysis, showsHours: !isSmall)
            verdict(analysis)
        }
    }

    private func header(_ analysis: ThermalAnalysis) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(analysis.series.isDemo ? Color.nadirDim : Color.nadirGo)
                .frame(width: 5, height: 5)
            Text(analysis.series.place.uppercased())
                .font(.nadirMono(isSmall ? 8.5 : 9.5))
                .tracking(0.5)
                .foregroundStyle(Color.nadirDim)
                .lineLimit(1)
            Spacer(minLength: 4)
            alarmBadge(analysis)
        }
    }

    /// L'alarme armée la plus proche : carré vert + heure. Rien si aucune.
    @ViewBuilder private func alarmBadge(_ analysis: ThermalAnalysis) -> some View {
        if let time = nextAlarmTime(analysis) {
            HStack(spacing: 4) {
                Rectangle()
                    .fill(Color.nadirGo)
                    .frame(width: 5, height: 5)
                Text(time)
                    .font(.nadirMono(isSmall ? 8.5 : 9.5))
                    .monospacedDigit()
                    .foregroundStyle(Color.nadirGo)
            }
            .accessibilityLabel("Alarme à \(time)")
        }
    }

    private func nextAlarmTime(_ analysis: ThermalAnalysis) -> String? {
        guard let window = analysis.firstWindow else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = analysis.series.timeZone
        func clock(_ date: Date) -> String {
            let parts = calendar.dateComponents([.hour, .minute], from: date)
            return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
        }
        if entry.alarmOnOpen, window.start > entry.date { return clock(window.start) }
        if entry.alarmOnClose, window.end > entry.date { return clock(window.end) }
        return nil
    }

    private func verdict(_ analysis: ThermalAnalysis) -> some View {
        Text(compactVerdict(analysis).uppercased())
            .font(.nadirSans(isSmall ? 13 : 15, weight: .heavy))
            .tracking(isSmall ? -0.3 : -0.4)
            .foregroundStyle(analysis.runs.isEmpty ? Color.nadirHot : Color.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }

    private func compactVerdict(_ analysis: ThermalAnalysis) -> String {
        guard let first = analysis.runs.first else { return "Gardez fermé" }
        if analysis.shouldOpenNow { return "Ouvrez jusqu'à \(analysis.endLabel(of: first))" }
        return "Ouvrez \(analysis.series.hourLabel(at: first.lowerBound))–\(analysis.endLabel(of: first))"
    }
}

/// La courbe, réduite à l'essentiel : bande verte du créneau, dehors en
/// blanc léger, chez vous en bleu, repère « maintenant ».
struct WidgetChart: View {
    let analysis: ThermalAnalysis
    let showsHours: Bool

    var body: some View {
        Canvas { context, size in
            let series = analysis.series
            let outdoor = series.outdoor
            let indoor = analysis.result.indoor
            let n = outdoor.count
            guard n > 1, indoor.count == n else { return }

            let padBottom: CGFloat = showsHours ? 13 : 2
            let plotBottom = size.height - padBottom
            let values = outdoor + indoor
            let lo = values.min()! - 0.8
            let hi = values.max()! + 0.8

            func x(_ i: Double) -> CGFloat {
                CGFloat(i / Double(n - 1)) * size.width
            }
            func y(_ t: Double) -> CGFloat {
                2 + CGFloat(1 - (t - lo) / (hi - lo)) * (plotBottom - 2)
            }
            func curve(_ samples: [Double]) -> Path {
                Path { path in
                    path.move(to: CGPoint(x: x(0), y: y(samples[0])))
                    for i in 1 ..< n { path.addLine(to: CGPoint(x: x(Double(i)), y: y(samples[i]))) }
                }
            }

            // Créneaux d'ouverture conseillés.
            for run in analysis.runs {
                let xa = x(max(0, Double(run.lowerBound) - 0.5))
                let xb = x(min(Double(n - 1), Double(run.upperBound) + 0.5))
                context.fill(
                    Path(CGRect(x: xa, y: 2, width: xb - xa, height: plotBottom - 2)),
                    with: .color(.nadirGo.opacity(0.14))
                )
            }

            // Dégradé sous « chez vous ».
            let indoorPath = curve(indoor)
            var indoorFill = indoorPath
            indoorFill.addLine(to: CGPoint(x: x(Double(n - 1)), y: plotBottom))
            indoorFill.addLine(to: CGPoint(x: x(0), y: plotBottom))
            indoorFill.closeSubpath()
            context.fill(
                indoorFill,
                with: .linearGradient(
                    Gradient(colors: [.nadirCold.opacity(0.18), .nadirCold.opacity(0)]),
                    startPoint: CGPoint(x: 0, y: indoorPath.boundingRect.minY),
                    endPoint: CGPoint(x: 0, y: plotBottom)
                )
            )

            // Dehors (léger) puis chez vous (net).
            context.stroke(
                curve(outdoor),
                with: .color(.white.opacity(0.34)),
                style: StrokeStyle(lineWidth: 1, lineJoin: .round)
            )
            context.stroke(
                indoorPath,
                with: .color(.nadirCold),
                style: StrokeStyle(lineWidth: 2, lineJoin: .round)
            )

            // Maintenant.
            context.stroke(
                Path { $0.move(to: CGPoint(x: x(0), y: 2)); $0.addLine(to: CGPoint(x: x(0), y: plotBottom)) },
                with: .color(.white.opacity(0.3)),
                lineWidth: 1
            )

            // Heures (widget moyen).
            if showsHours {
                for i in stride(from: 0, to: n, by: 6) {
                    context.draw(
                        Text(series.hourLabel(at: i))
                            .font(.nadirMono(8))
                            .foregroundStyle(Color.nadirFaint),
                        at: CGPoint(x: min(max(x(Double(i)), 10), size.width - 10), y: size.height - 5),
                        anchor: .center
                    )
                }
            }
        }
        .accessibilityLabel("Température extérieure et intérieure modélisée")
    }
}
