import SwiftUI

/// Le graphe : extérieur (trait fin blanc) et intérieur modélisé (bleu, la
/// star), créneaux d'ouverture conseillés en vert, écart coté au plus chaud.
/// Le tracé s'anime à chaque nouvelle source météo.
struct ChartView: View {
    let analysis: ThermalAnalysis
    /// Change à chaque nouvelle source météo : rejoue l'animation.
    let animationKey: Int
    /// L'animation de cette source a déjà été jouée (retour d'onglet).
    let hasPlayed: Bool
    let onPlayed: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animationStart: Date?
    @State private var isAnimating = false
    @State private var animationGeneration = 0

    private static let height: CGFloat = 300
    private static let totalDuration: TimeInterval = 2.4

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !isAnimating)) { timeline in
            Canvas { context, size in
                draw(in: &context, size: size, phase: phase(at: timeline.date))
            }
        }
        .frame(height: Self.height)
        .onAppear { if !hasPlayed { startAnimation() } }
        .onChange(of: animationKey) { startAnimation() }
        .accessibilityLabel("Température extérieure et intérieure modélisée")
    }

    // MARK: - Animation

    private struct Phase {
        var outdoorTrim: CGFloat
        var indoorTrim: CGFloat
        var fade: Double
        /// Verrouillage sur « maintenant » : 0 → 1 pendant l'entrée, fini au-delà.
        var lockOn: Double

        static let settled = Phase(outdoorTrim: 1, indoorTrim: 1, fade: 1, lockOn: 2)
    }

    private func startAnimation() {
        onPlayed()
        guard !reduceMotion else { return }
        animationStart = .now
        isAnimating = true
        // Jeton de génération : la fin d'une animation précédente ne doit pas
        // figer celle qui vient de démarrer.
        animationGeneration += 1
        let generation = animationGeneration
        Task {
            try? await Task.sleep(for: .seconds(Self.totalDuration))
            if generation == animationGeneration { isAnimating = false }
        }
    }

    private func phase(at date: Date) -> Phase {
        guard let start = animationStart, !reduceMotion else { return .settled }
        let t = date.timeIntervalSince(start)
        guard t < Self.totalDuration else { return .settled }
        func ease(_ x: Double) -> Double {
            let c = min(1, max(0, x))
            return c * c * (3 - 2 * c)
        }
        return Phase(
            outdoorTrim: ease((t - 0.1) / 1.3),
            indoorTrim: ease((t - 0.85) / 1.3),
            fade: min(1, max(0, (t - 0.9) / 0.8)),
            lockOn: (t - 0.1) / 0.9
        )
    }

    // MARK: - Dessin

    private func draw(in context: inout GraphicsContext, size: CGSize, phase: Phase) {
        let series = analysis.series
        let outdoor = series.outdoor
        let indoor = analysis.result.indoor
        let n = outdoor.count
        guard n > 1, indoor.count == n else { return }

        let width = size.width
        let height = size.height
        let padLeft: CGFloat = 44, padRight: CGFloat = 18
        let padTop: CGFloat = 22, padBottom: CGFloat = 36
        let plotBottom = height - padBottom

        let values = outdoor + indoor
        let lo = values.min()! - 1.5
        let hi = values.max()! + 1.5

        func x(_ i: Double) -> CGFloat {
            padLeft + CGFloat(i / Double(n - 1)) * (width - padLeft - padRight)
        }
        func y(_ t: Double) -> CGFloat {
            padTop + CGFloat(1 - (t - lo) / (hi - lo)) * (plotBottom - padTop)
        }
        func curve(_ samples: [Double]) -> Path {
            Path { path in
                path.move(to: CGPoint(x: x(0), y: y(samples[0])))
                for i in 1 ..< n { path.addLine(to: CGPoint(x: x(Double(i)), y: y(samples[i]))) }
            }
        }
        func text(_ string: String, size: CGFloat, color: Color, weight: Font.Weight = .regular) -> Text {
            Text(string).font(.nadirMono(size, weight: weight)).foregroundStyle(color)
        }

        // Créneaux d'ouverture conseillés.
        for run in analysis.runs {
            let xa = x(max(0, Double(run.lowerBound) - 0.5))
            let xb = x(min(Double(n - 1), Double(run.upperBound) + 0.5))
            let band = CGRect(x: xa, y: padTop, width: xb - xa, height: plotBottom - padTop)
            context.fill(Path(band), with: .color(.nadirGo.opacity(0.10 * phase.fade)))
        }

        // Graduations de température.
        let span = hi - lo
        let step: Double = span > 18 ? 5 : span > 9 ? 4 : 2
        var mark = (lo / step).rounded(.up) * step
        while mark <= hi {
            let my = y(mark)
            context.stroke(
                Path { $0.move(to: CGPoint(x: padLeft, y: my)); $0.addLine(to: CGPoint(x: width - padRight, y: my)) },
                with: .color(.white.opacity(0.06)), lineWidth: 1
            )
            context.draw(
                text("\(Int(mark))°", size: 10, color: .nadirDim),
                at: CGPoint(x: padLeft - 6, y: my), anchor: .trailing
            )
            mark += step
        }

        // « Plus frais que dehors » : aire entre l'extérieur et l'intérieur.
        var coolerFill = Path()
        coolerFill.move(to: CGPoint(x: x(0), y: y(max(outdoor[0], indoor[0]))))
        for i in 1 ..< n { coolerFill.addLine(to: CGPoint(x: x(Double(i)), y: y(max(outdoor[i], indoor[i])))) }
        for i in stride(from: n - 1, through: 0, by: -1) {
            coolerFill.addLine(to: CGPoint(x: x(Double(i)), y: y(indoor[i])))
        }
        coolerFill.closeSubpath()
        context.fill(coolerFill, with: .color(.nadirCold.opacity(0.14 * phase.fade)))

        // Graduations horaires.
        for i in stride(from: 0, to: n, by: 3) {
            let hx = x(Double(i))
            context.stroke(
                Path { $0.move(to: CGPoint(x: hx, y: plotBottom)); $0.addLine(to: CGPoint(x: hx, y: plotBottom + 4)) },
                with: .color(Color(white: 42 / 255)), lineWidth: 1
            )
            context.draw(
                text(series.hourLabel(at: i), size: 10, color: .nadirDim),
                at: CGPoint(x: hx, y: plotBottom + 11), anchor: .center
            )
        }

        // Passage(s) à minuit.
        var tomorrowLabelled = false
        for i in 1 ..< n where series.hour(at: i) == 0 {
            let mx = x(Double(i))
            context.stroke(
                Path { $0.move(to: CGPoint(x: mx, y: padTop)); $0.addLine(to: CGPoint(x: mx, y: plotBottom)) },
                with: .color(.white.opacity(0.14)),
                style: StrokeStyle(lineWidth: 1, dash: [3, 5])
            )
            if !tomorrowLabelled {
                context.draw(
                    text("demain", size: 9, color: .nadirDim),
                    at: CGPoint(x: mx + 5, y: plotBottom - 12), anchor: .leading
                )
                tomorrowLabelled = true
            }
        }

        // Dégradé sous la courbe intérieure + halo : « chez vous » est la star.
        let indoorPath = curve(indoor)
        var indoorFill = indoorPath
        indoorFill.addLine(to: CGPoint(x: x(Double(n - 1)), y: plotBottom))
        indoorFill.addLine(to: CGPoint(x: x(0), y: plotBottom))
        indoorFill.closeSubpath()
        context.fill(
            indoorFill,
            with: .linearGradient(
                Gradient(colors: [.nadirCold.opacity(0.20 * phase.fade), .nadirCold.opacity(0)]),
                startPoint: CGPoint(x: 0, y: indoorPath.boundingRect.minY),
                endPoint: CGPoint(x: 0, y: plotBottom)
            )
        )
        context.stroke(indoorPath, with: .color(.nadirCold.opacity(0.10 * phase.fade)), lineWidth: 10)
        context.stroke(indoorPath, with: .color(.nadirCold.opacity(0.18 * phase.fade)), lineWidth: 5)

        // Dehors (léger) puis chez vous (net) ; tracé animé.
        let outdoorPath = curve(outdoor)
        context.stroke(
            outdoorPath.trimmedPath(from: 0, to: phase.outdoorTrim),
            with: .color(.white.opacity(0.34)),
            style: StrokeStyle(lineWidth: 1.5, lineJoin: .round)
        )
        context.stroke(
            indoorPath.trimmedPath(from: 0, to: phase.indoorTrim),
            with: .color(.nadirCold),
            style: StrokeStyle(lineWidth: 2.6, lineJoin: .round)
        )

        // Noms des courbes à leur extrémité (remplace la légende) —
        // l'anti-collision s'applique aux positions finales des labels.
        var outdoorLabelY = y(outdoor[n - 1]) - 10
        var indoorLabelY = y(indoor[n - 1]) + 12
        if abs(outdoorLabelY - indoorLabelY) < 16 {
            let center = (outdoorLabelY + indoorLabelY) / 2
            let sign: CGFloat = outdoorLabelY <= indoorLabelY ? 1 : -1
            outdoorLabelY = center - 8 * sign
            indoorLabelY = center + 8 * sign
        }
        context.draw(
            text("dehors", size: 11, color: .white.opacity(0.6 * phase.fade)),
            at: CGPoint(x: width - padRight - 2, y: outdoorLabelY), anchor: .trailing
        )
        context.draw(
            text("chez vous", size: 11, color: .nadirCold.opacity(phase.fade)),
            at: CGPoint(x: width - padRight - 2, y: indoorLabelY), anchor: .trailing
        )

        // Cote d'efficacité au moment le plus chaud.
        let peak = analysis.peakIndex
        let gap = outdoor[peak] - indoor[peak]
        if gap > 0.6 {
            let gx = x(Double(peak))
            let y1 = y(outdoor[peak]), y2 = y(indoor[peak])
            var gauge = Path()
            gauge.move(to: CGPoint(x: gx, y: y1)); gauge.addLine(to: CGPoint(x: gx, y: y2))
            gauge.move(to: CGPoint(x: gx - 4, y: y1)); gauge.addLine(to: CGPoint(x: gx + 4, y: y1))
            gauge.move(to: CGPoint(x: gx - 4, y: y2)); gauge.addLine(to: CGPoint(x: gx + 4, y: y2))
            context.stroke(gauge, with: .color(.white.opacity(phase.fade)), lineWidth: 1.5)
            let onRight = gx > width - 140
            context.draw(
                text("\(gap.oneDecimal) °C plus frais", size: 11, color: .white.opacity(phase.fade)),
                at: CGPoint(x: onRight ? gx - 8 : gx + 8, y: (y1 + y2) / 2),
                anchor: onRight ? .trailing : .leading
            )
        }

        // Repère du minimum dehors.
        let coolest = analysis.coolestIndex
        let cx = x(Double(coolest)), cy = y(outdoor[coolest])
        context.stroke(
            Path(ellipseIn: CGRect(x: cx - 3.5, y: cy - 3.5, width: 7, height: 7)),
            with: .color(.white.opacity(0.55)), lineWidth: 1.5
        )
        context.draw(
            text("min \(outdoor[coolest].noDecimal)°", size: 10, color: .nadirDim),
            at: CGPoint(x: cx, y: cy + 11), anchor: .center
        )

        // Maintenant.
        context.stroke(
            Path { $0.move(to: CGPoint(x: x(0), y: padTop)); $0.addLine(to: CGPoint(x: x(0), y: plotBottom)) },
            with: .color(.white.opacity(0.35)), lineWidth: 1
        )
        context.draw(
            text("maintenant", size: 10, color: .nadirDim),
            at: CGPoint(x: x(0) + 4, y: padTop + 6), anchor: .leading
        )

        // Lieu.
        context.draw(
            text(series.place, size: 11, color: .white),
            at: CGPoint(x: width - padRight, y: padTop + 6), anchor: .trailing
        )

        // Verrouillage : un cercle fin se resserre sur « maintenant » —
        // l'app se centre sur vous.
        if phase.lockOn >= 0, phase.lockOn < 1 {
            let p = phase.lockOn
            let eased = 1 - pow(1 - p, 3)
            let center = CGPoint(x: x(0), y: y(indoor[0]))
            let radius = 70 - 63 * eased
            let alpha = 0.85 * (1 - p * p)
            context.stroke(
                Path(ellipseIn: CGRect(
                    x: center.x - radius, y: center.y - radius,
                    width: radius * 2, height: radius * 2
                )),
                with: .color(.white.opacity(alpha)), lineWidth: 1
            )
            var ticks = Path()
            for angle in stride(from: 0.0, to: 2 * .pi, by: .pi / 2) {
                let dx = cos(angle), dy = sin(angle)
                ticks.move(to: CGPoint(x: center.x + dx * (radius + 3), y: center.y + dy * (radius + 3)))
                ticks.addLine(to: CGPoint(x: center.x + dx * (radius + 9), y: center.y + dy * (radius + 9)))
            }
            context.stroke(ticks, with: .color(.white.opacity(alpha)), lineWidth: 1)
        }
    }
}
