import SwiftUI

/// Me prévenir : une notification à l'heure d'ouvrir (ou d'aérer) et à
/// l'heure de fermer. Celle d'ouverture se grise si l'heure est passée.
struct AlarmsSection: View {
    @Environment(AppModel.self) private var model
    let window: AppModel.AlarmWindow
    /// Mode aérer : « aérer » et « refermer » au lieu d'« ouvrir » et « fermer ».
    let isAiring: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "Me prévenir")
                .padding(.bottom, 6)

            alarmRow(
                kind: .open,
                title: isAiring ? "À l’heure d’aérer" : "À l’heure d’ouvrir",
                meta: window.startIsPast ? "C’est déjà l’heure" : model.delayLabel(until: window.start).capitalizedFirst,
                time: model.clockLabel(for: window.start),
                isOn: model.profile.alarmOnOpen && !window.startIsPast,
                isDisabled: window.startIsPast
            )

            alarmRow(
                kind: .close,
                title: isAiring ? "À l’heure de refermer" : "À l’heure de fermer",
                meta: model.delayLabel(until: window.end).capitalizedFirst,
                time: model.clockLabel(for: window.end),
                isOn: model.profile.alarmOnClose,
                isDisabled: false
            )
            .overlay(alignment: .bottom) { Color.nadirLine.frame(height: 1) }

            Text("La notification arrive même si l’app est fermée, puis se répète deux fois, à 3 minutes d’intervalle.")
                .font(.nadirSans(13))
                .lineSpacing(3)
                .foregroundStyle(Color.nadirDim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 24)
    }

    private func alarmRow(
        kind: AlarmScheduler.Kind,
        title: String,
        meta: String,
        time: String,
        isOn: Bool,
        isDisabled: Bool
    ) -> some View {
        let ink: Color = isDisabled ? .nadirFaint : .white
        return HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.nadirSans(16, weight: .semibold))
                    .foregroundStyle(ink)
                Text(meta)
                    .font(.nadirSans(13))
                    .foregroundStyle(Color.nadirDim)
            }
            Spacer(minLength: 0)
            Text(time)
                .font(.nadirSans(17, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(ink)
            Toggle(title, isOn: Binding(
                get: { isOn },
                set: { _ in Task { await model.toggleAlarm(kind) } }
            ))
            .labelsHidden()
            .toggleStyle(NadirToggleStyle())
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
    }
}
