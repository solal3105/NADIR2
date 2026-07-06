import SwiftUI

/// Entrée du design (« tnUp ») : fondu + remontée de 14 pt, courbe
/// cubic-bezier(.22, .7, .25, 1). Rejouée quand `trigger` change ;
/// immédiate si `animated` est faux ou si l'utilisateur réduit les
/// animations.
struct RiseInModifier: ViewModifier {
    let trigger: Int
    let animated: Bool
    let delay: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                if animated { play() } else { shown = true }
            }
            .onChange(of: trigger) { play() }
    }

    private func play() {
        guard !reduceMotion else { shown = true; return }
        shown = false
        withAnimation(.timingCurve(0.22, 0.7, 0.25, 1, duration: 0.7).delay(delay)) {
            shown = true
        }
    }
}

extension View {
    func riseIn(trigger: Int, animated: Bool = true, delay: Double = 0) -> some View {
        modifier(RiseInModifier(trigger: trigger, animated: animated, delay: delay))
    }
}
