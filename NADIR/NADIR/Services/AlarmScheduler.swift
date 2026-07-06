import UserNotifications

/// Alarmes système : notifications locales au moment d'ouvrir et de fermer.
/// Chacune sonne même app fermée, puis se répète à +3 et +6 min avant de
/// s'arrêter.
struct AlarmScheduler {
    enum Kind: String, CaseIterable {
        case open, close

        var title: String {
            switch self {
            case .open: "Ouvrez en grand"
            case .close: "Fermez tout"
            }
        }

        var body: String {
            switch self {
            case .open:
                "Il fait plus frais dehors que chez vous. L'air de la nuit recharge vos murs en fraîcheur."
            case .close:
                "Dehors se réchauffe. Fermez fenêtres et volets pour enfermer la fraîcheur."
            }
        }
    }

    private static let repeatOffsets: [TimeInterval] = [0, 180, 360]

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func schedule(_ kind: Kind, at date: Date) {
        cancel(kind)
        let center = UNUserNotificationCenter.current()
        for (index, offset) in Self.repeatOffsets.enumerated() {
            let delay = date.addingTimeInterval(offset).timeIntervalSinceNow
            guard delay > 0 else { continue }
            let content = UNMutableNotificationContent()
            content.title = kind.title
            content.body = kind.body
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
