import AppIntents
import WidgetKit

/// Sans lieu configuré, NADIR n'a que des données d'exemple : plutôt que
/// d'énoncer un verdict inventé, les raccourcis échouent proprement.
enum NadirIntentError: Error, CustomLocalizedStringResourceConvertible {
    case notConfigured

    var localizedStringResource: LocalizedStringResource {
        "Configurez d'abord votre lieu dans NADIR : votre ville, ou votre position."
    }
}

/// « Le verdict NADIR » : la consigne du moment, dictée par Siri ou
/// utilisée dans une automatisation Raccourcis.
struct GetVerdictIntent: AppIntent {
    static let title: LocalizedStringResource = "Obtenir le verdict"
    static let description = IntentDescription(
        "Donne la consigne du moment : quand ouvrir et quand fermer les fenêtres.",
        categoryName: "Verdict"
    )

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let analysis = await SeriesProvider.currentAnalysis(profile: UserProfile.load())
        guard !analysis.series.isDemo else { throw NadirIntentError.notConfigured }
        var verdict = analysis.verdictTitle
        if let second = analysis.secondWindowLabel {
            verdict += ". Un deuxième créneau s'ouvre \(second)."
        }
        return .result(value: verdict, dialog: IntentDialog(stringLiteral: verdict))
    }
}

/// Vrai si c'est le moment d'ouvrir : la condition idéale pour piloter des
/// volets ou une VMC connectés (HomeKit, Matter) depuis une automatisation.
struct ShouldOpenNowIntent: AppIntent {
    static let title: LocalizedStringResource = "Faut-il ouvrir maintenant ?"
    static let description = IntentDescription(
        "Vrai si c'est le moment d'ouvrir les fenêtres. À utiliser comme condition dans vos automatisations.",
        categoryName: "Verdict"
    )

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> & ProvidesDialog {
        let analysis = await SeriesProvider.currentAnalysis(profile: UserProfile.load())
        guard !analysis.series.isDemo else { throw NadirIntentError.notConfigured }
        let shouldOpen = analysis.shouldOpenNow
        let dialog: IntentDialog = shouldOpen
            ? "Oui : il fait plus frais dehors, ouvrez en grand."
            : "Non : gardez fermé pour l'instant."
        return .result(value: shouldOpen, dialog: dialog)
    }
}

/// Met à jour la température mesurée chez vous — par exemple envoyée par un
/// capteur connecté (HomeKit, Matter) via une automatisation Raccourcis.
struct SetIndoorTemperatureIntent: AppIntent {
    static let title: LocalizedStringResource = "Régler la température intérieure"
    static let description = IntentDescription(
        "Met à jour la température chez vous, par exemple depuis un capteur connecté.",
        categoryName: "Réglages"
    )

    @Parameter(title: "Température (°C)", inclusiveRange: (20, 34))
    var temperature: Double

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Même pas que le curseur de l'app : demi-degré, borné 20–34 °C.
        let clamped = (min(34, max(20, temperature)) * 2).rounded() / 2
        if let model = AppModel.shared {
            // L'app vit dans ce process : passer par son état évite d'écraser
            // un réglage en mémoire, et resynchronise aussitôt les alarmes.
            model.setIndoor(clamped)
        } else {
            var profile = UserProfile.load()
            profile.indoorNow = clamped
            profile.save()
        }
        WidgetCenter.shared.reloadAllTimelines()
        return .result(dialog: "Température intérieure réglée sur \(clamped.oneDecimal) °C.")
    }
}

struct NadirAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetVerdictIntent(),
            phrases: [
                "Le verdict \(.applicationName)",
                "Demande le verdict à \(.applicationName)",
                "Quand ouvrir les fenêtres avec \(.applicationName)",
            ],
            shortTitle: "Le verdict",
            systemImageName: "wind"
        )
        AppShortcut(
            intent: ShouldOpenNowIntent(),
            phrases: [
                "Faut-il ouvrir les fenêtres \(.applicationName)",
                "Est-ce que je peux ouvrir \(.applicationName)",
            ],
            shortTitle: "Ouvrir maintenant ?",
            systemImageName: "window.casement"
        )
    }
}
