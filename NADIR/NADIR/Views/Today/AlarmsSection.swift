import SwiftUI

/// Alarmes système au moment d'ouvrir et de fermer : heure visée, délai,
/// interrupteur. Celle d'ouverture se grise si le créneau a déjà commencé.
struct AlarmsSection: View {
    @Environment(AppModel.self) private var model
    let window: AppModel.AlarmWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "Alarmes")
                .padding(.bottom, 4)

            alarmRow(
                kind: .open,
                title: "Au moment d'ouvrir",
                meta: window.startIsPast ? "Créneau déjà ouvert" : model.delayLabel(until: window.start),
                time: model.clockLabel(for: window.start),
                isOn: model.profile.alarmOnOpen && !window.startIsPast,
                isDisabled: window.startIsPast
            )

            alarmRow(
                kind: .close,
                title: "Au moment de fermer",
                meta: model.delayLabel(until: window.end),
                time: model.clockLabel(for: window.end),
                isOn: model.profile.alarmOnClose,
                isDisabled: false
            )
            .overlay(alignment: .bottom) { Color.nadirLine.frame(height: 1) }

            Text("Alarme système : sonne même app fermée, puis se répète à +3 et +6 min avant de s'arrêter.")
                .font(.nadirMono(10))
                .lineSpacing(4)
                .foregroundStyle(Color.nadirLine2)
                .padding(.top, 10)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 4)
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
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.nadirSans(16, weight: .semibold))
                    .foregroundStyle(ink)
                Text(meta)
                    .font(.nadirMono(11.5))
                    .foregroundStyle(Color.nadirFaint)
            }
            Spacer(minLength: 0)
            Text(time)
                .font(.nadirMono(16))
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
        .padding(.vertical, 16)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
    }
}
