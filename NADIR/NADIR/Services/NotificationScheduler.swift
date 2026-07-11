import UserNotifications

/// Notifications système : une seule au moment d'ouvrir, une seule au
/// moment de fermer. Chacune arrive même app fermée, et ne vaut que pour
/// le créneau en cours.
struct NotificationScheduler {
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

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func schedule(_ kind: Kind, at date: Date) {
        cancel(kind)
        let delay = date.timeIntervalSinceNow
        guard delay > 0 else { return }
        let content = UNMutableNotificationContent()
        content.title = kind.title
        content.body = kind.body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        UNUserNotificationCenter.current().add(UNNotificationRequest(
            identifier: identifier(kind), content: content, trigger: trigger
        ))
    }

    func cancel(_ kind: Kind) {
        // Les identifiants suffixés purgent les répétitions +3 et +6 min
        // programmées par les versions précédentes.
        let legacy = (0 ..< 3).map { "nadir.alarm.\(kind.rawValue).\($0)" }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier(kind)] + legacy)
    }

    private func identifier(_ kind: Kind) -> String {
        "nadir.notify.\(kind.rawValue)"
    }
}
