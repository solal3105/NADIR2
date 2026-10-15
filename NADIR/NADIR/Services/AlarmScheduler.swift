import UserNotifications

/// Alarmes système : notifications locales au moment d'ouvrir et de fermer.
/// Chacune sonne même app fermée, puis se répète à +3 et +6 min avant de
/// s'arrêter.
struct AlarmScheduler {
    enum Kind: String, CaseIterable {
        case open, close

        func title(airing: Bool) -> String {
            switch (self, airing) {
            case (.open, false): "C’est l’heure d’ouvrir"
            case (.close, false): "C’est l’heure de fermer"
            case (.open, true): "C’est l’heure d’aérer"
            case (.close, true): "Vous pouvez refermer"
            }
        }

        func body(airing: Bool) -> String {
            switch (self, airing) {
            case (.open, false):
                "Il fait plus frais dehors que chez vous. Ouvrez grand vos fenêtres."
            case (.close, false):
                "Dehors, il commence à faire plus chaud. Fermez fenêtres et volets pour garder la fraîcheur."
            case (.open, true):
                "C’est le moment le plus doux de la journée. Ouvrez grand quelques minutes."
            case (.close, true):
                "L’air est renouvelé. Refermez pour garder la chaleur."
            }
        }
    }

    private static let repeatOffsets: [TimeInterval] = [0, 180, 360]

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func schedule(_ kind: Kind, at date: Date, airing: Bool = false) {
        cancel(kind)
        let center = UNUserNotificationCenter.current()
        for (index, offset) in Self.repeatOffsets.enumerated() {
            let delay = date.addingTimeInterval(offset).timeIntervalSinceNow
            guard delay > 0 else { continue }
            let content = UNMutableNotificationContent()
            content.title = kind.title(airing: airing)
            content.body = kind.body(airing: airing)
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            center.add(UNNotificationRequest(
                identifier: identifier(kind, index), content: content, trigger: trigger
            ))
        }
    }

    func cancel(_ kind: Kind) {
        let identifiers = Self.repeatOffsets.indices.map { identifier(kind, $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func identifier(_ kind: Kind, _ index: Int) -> String {
        "nadir.alarm.\(kind.rawValue).\(index)"
    }
}
