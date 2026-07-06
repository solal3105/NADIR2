import SwiftUI

/// Interrupteur du design : rail sombre au repos, vert quand actif,
/// bouton blanc. L'état éteint reste clairement éteint, même en mode sombre.
struct NadirToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Capsule()
                .fill(configuration.isOn ? Color.nadirGo : Color.nadirSwitchOff)
                .frame(width: 51, height: 31)
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle()
                        .fill(.white)
                        .frame(width: 27, height: 27)
                        .shadow(color: .black.opacity(0.5), radius: 1.5, y: 1)
                        .padding(2)
                }
                .animation(.easeOut(duration: 0.2), value: configuration.isOn)
        }
        .buttonStyle(.plain)
        .accessibilityValue(configuration.isOn ? "activé" : "désactivé")
    }
}
