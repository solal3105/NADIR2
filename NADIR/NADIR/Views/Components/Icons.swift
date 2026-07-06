import SwiftUI

/// Viseur de géolocalisation (cercle + quatre ticks).
struct CrosshairIcon: View {
    var color: Color = .white
    var size: CGFloat = 14

    var body: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width / 14
            context.stroke(
                Path(ellipseIn: CGRect(x: 4 * s, y: 4 * s, width: 6 * s, height: 6 * s)),
                with: .color(color), lineWidth: 1.4 * s
            )
            var ticks = Path()
            ticks.move(to: CGPoint(x: 7 * s, y: 0.5 * s)); ticks.addLine(to: CGPoint(x: 7 * s, y: 2.5 * s))
            ticks.move(to: CGPoint(x: 7 * s, y: 11.5 * s)); ticks.addLine(to: CGPoint(x: 7 * s, y: 13.5 * s))
            ticks.move(to: CGPoint(x: 0.5 * s, y: 7 * s)); ticks.addLine(to: CGPoint(x: 2.5 * s, y: 7 * s))
            ticks.move(to: CGPoint(x: 11.5 * s, y: 7 * s)); ticks.addLine(to: CGPoint(x: 13.5 * s, y: 7 * s))
            context.stroke(ticks, with: .color(color), lineWidth: 1.4 * s)
        }
        .frame(width: size, height: size)
    }
}

/// Viseur de géolocalisation avec une onde concentrique pendant la
/// recherche : l'app vous cherche, puis se centre sur vous.
struct LocatingCrosshair: View {
    let active: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    var body: some View {
        CrosshairIcon()
            .background {
                if active && !reduceMotion {
                    Circle()
                        .stroke(.white, lineWidth: 1)
                        .frame(width: 14, height: 14)
                        .scaleEffect(pulsing ? 2.6 : 0.6)
                        .opacity(pulsing ? 0 : 0.8)
                        .animation(
                            .easeOut(duration: 1.1).repeatForever(autoreverses: false),
                            value: pulsing
                        )
                        .onAppear { pulsing = true }
                        .onDisappear { pulsing = false }
                }
            }
    }
}

/// Pictogrammes fenêtre + soleil des quatre gestes (viewbox 44 × 44).
struct WindowIcon: View {
    enum Glyph {
        /// Soleil blanc, air frais qui entre : ouvrez en grand.
        case openNight
        /// Soleil rouge, volets baissés : fermez tout.
        case closeShutters
        /// Soleil rouge, fenêtre barrée : restez fermé.
        case stayClosed
        /// Soleil rouge évidé, air frais qui rentre : rouvrez.
        case reopen
    }

    let glyph: Glyph
    var size: CGFloat = 38

    var body: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width / 44
            func point(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * s, y: y * s) }
            func line(_ path: inout Path, _ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {
                path.move(to: point(x1, y1))
                path.addLine(to: point(x2, y2))
            }

            // Soleil.
            switch glyph {
            case .openNight:
                context.fill(
                    Path(ellipseIn: CGRect(x: 32 * s, y: 4 * s, width: 8 * s, height: 8 * s)),
                    with: .color(.white)
                )
            case .closeShutters, .stayClosed:
                context.fill(
                    Path(ellipseIn: CGRect(x: 31.5 * s, y: 3.5 * s, width: 9 * s, height: 9 * s)),
                    with: .color(.nadirHot)
                )
            case .reopen:
                context.stroke(
                    Path(ellipseIn: CGRect(x: 31.5 * s, y: 3.5 * s, width: 9 * s, height: 9 * s)),
                    with: .color(.nadirHot), lineWidth: 2 * s
                )
            }

            // Fenêtre.
            context.stroke(
                Path(CGRect(x: 10 * s, y: 12 * s, width: 24 * s, height: 24 * s)),
                with: .color(.white), lineWidth: 2 * s
            )

            // Contenu.
            switch glyph {
            case .openNight, .reopen:
                var arrow = Path()
                line(&arrow, 2, 24, 26, 24)
                context.stroke(arrow, with: .color(.nadirCold), lineWidth: 2 * s)
                var head = Path()
                head.move(to: point(34, 24))
                head.addLine(to: point(25, 20))
                head.addLine(to: point(25, 28))
                head.closeSubpath()
                context.fill(head, with: .color(.nadirCold))
            case .closeShutters:
                var shutters = Path()
                line(&shutters, 13, 19, 31, 19)
                line(&shutters, 13, 25, 31, 25)
                line(&shutters, 13, 31, 31, 31)
                context.stroke(shutters, with: .color(.white), lineWidth: 2 * s)
            case .stayClosed:
                var cross = Path()
                line(&cross, 15, 17, 29, 31)
                line(&cross, 29, 17, 15, 31)
                context.stroke(cross, with: .color(.white), lineWidth: 2 * s)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Double flèche traversante (note d'exposition sur deux façades).
struct CrossDraftIcon: View {
    var size: CGFloat = 15

    var body: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width / 15
            var path = Path()
            path.move(to: CGPoint(x: 1 * s, y: 5 * s)); path.addLine(to: CGPoint(x: 14 * s, y: 5 * s))
            path.move(to: CGPoint(x: 1 * s, y: 10 * s)); path.addLine(to: CGPoint(x: 14 * s, y: 10 * s))
            path.move(to: CGPoint(x: 4.5 * s, y: 2.5 * s))
            path.addLine(to: CGPoint(x: 1 * s, y: 5 * s))
            path.addLine(to: CGPoint(x: 4.5 * s, y: 7.5 * s))
            path.move(to: CGPoint(x: 10.5 * s, y: 7.5 * s))
            path.addLine(to: CGPoint(x: 14 * s, y: 10 * s))
            path.addLine(to: CGPoint(x: 10.5 * s, y: 12.5 * s))
            context.stroke(path, with: .color(.nadirGo), lineWidth: 1.5 * s)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Icônes de la barre d'onglets (viewbox 26 × 26).
struct TabIcon: View {
    enum Glyph {
        /// Fenêtre à croisillons : Aujourd'hui.
        case today
        /// Soleil levant : Le geste.
        case guide
        /// Cible : Comprendre.
        case learn
        /// Silhouette : À propos.
        case about
    }

    let glyph: Glyph
    var size: CGFloat = 24

    var body: some View {
        Canvas { context, canvasSize in
            let s = canvasSize.width / 26
            func point(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: x * s, y: y * s) }
            let style = StrokeStyle(lineWidth: 2 * s, lineCap: .round)

            switch glyph {
            case .today:
                var path = Path(CGRect(x: 4 * s, y: 4 * s, width: 18 * s, height: 18 * s))
                path.move(to: point(13, 4)); path.addLine(to: point(13, 22))
                path.move(to: point(4, 13)); path.addLine(to: point(22, 13))
                context.stroke(path, with: .style(.currentTabColor), style: StrokeStyle(lineWidth: 2 * s))
            case .guide:
                var path = Path()
                path.move(to: point(3, 19.5)); path.addLine(to: point(23, 19.5))
                path.move(to: point(8, 19.5))
                path.addArc(
                    center: point(13, 19.5), radius: 5 * s,
                    startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false
                )
                path.move(to: point(13, 5.5)); path.addLine(to: point(13, 8.5))
                path.move(to: point(5, 11.5)); path.addLine(to: point(7, 13.5))
                path.move(to: point(21, 11.5)); path.addLine(to: point(19, 13.5))
                context.stroke(path, with: .style(.currentTabColor), style: style)
            case .learn:
                var path = Path(ellipseIn: CGRect(x: 4 * s, y: 4 * s, width: 18 * s, height: 18 * s))
                path.addEllipse(in: CGRect(x: 9.8 * s, y: 9.8 * s, width: 6.4 * s, height: 6.4 * s))
                context.stroke(path, with: .style(.currentTabColor), style: StrokeStyle(lineWidth: 2 * s))
            case .about:
                var path = Path(ellipseIn: CGRect(x: 9.5 * s, y: 4 * s, width: 7 * s, height: 7 * s))
                path.move(to: point(5.5, 22))
                path.addArc(
                    center: point(13, 22), radius: 7.5 * s,
                    startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false
                )
                context.stroke(path, with: .style(.currentTabColor), style: style)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

private extension ShapeStyle where Self == ForegroundStyle {
    /// La couleur d'onglet vient du `foregroundStyle` posé par le parent.
    static var currentTabColor: ForegroundStyle { ForegroundStyle() }
}
