import AppIntents
import WidgetKit

/// Sans lieu configuré, NADIR n'a que des données d'exemple : plutôt que
/// d'énoncer un verdict inventé, les raccourcis échouent proprement.
enum NadirIntentError: Error, CustomLocalizedStringResourceConvertible {
    case notConfigured

    var localizedStringResource: LocalizedStringResource {
        "Indiquez d’abord votre ville dans NADIR."
    }
}

/// « Le conseil NADIR » : le conseil du moment, dicté par Siri ou utilisé
/// dans une automatisation Raccourcis.
struct GetVerdictIntent: AppIntent {
    static let title: LocalizedStringResource = "Obtenir le conseil"
    static let description = IntentDescription(
        "Donne le conseil du moment : quand ouvrir et fermer vos fenêtres, ou quand aérer.",
        categoryName: "Conseil"
    )

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let advice = await SeriesProvider.currentAdvice(profile: UserProfile.load())
        let analysis = advice.analysis
        guard !analysis.series.isDemo else { throw NadirIntentError.notConfigured }
        var verdict = advice.verdictTitle
        if let aeration = advice.aeration {
            verdict += ". Ouvrez grand pendant \(aeration.minutes) minutes."
        } else if let second = analysis.secondWindowLabel {
            verdict += ". Vous pourrez rouvrir \(second)."
        } else {
            verdict += "."
        }
        return .result(value: verdict, dialog: IntentDialog(stringLiteral: verdict))
    }
}

/// Vrai si c'est le moment d'ouvrir : la condition idéale pour piloter des
/// volets ou une VMC connectés (HomeKit, Matter) depuis une automatisation.
struct ShouldOpenNowIntent: AppIntent {
    static let title: LocalizedStringResource = "Faut-il ouvrir maintenant ?"
    static let description = IntentDescription(
        "Répond oui si c’est le moment d’ouvrir, ou d’aérer. Pratique comme condition dans une automatisation.",
        categoryName: "Conseil"
    )

    func perform() async throws -> some IntentResult & ReturnsValue<Bool> & ProvidesDialog {
        let advice = await SeriesProvider.currentAdvice(profile: UserProfile.load())
        guard !advice.analysis.series.isDemo else { throw NadirIntentError.notConfigured }
        let shouldOpen = advice.shouldOpenNow
        let dialog: IntentDialog = switch (shouldOpen, advice.aeration) {
        case (true, nil): "Oui, il fait plus frais dehors. Ouvrez grand."
        case (true, let aeration?):
            IntentDialog(stringLiteral: "Oui, c’est le moment le plus doux de la journée. Aérez \(aeration.minutes) minutes.")
        case (false, _): "Non, gardez fermé pour l’instant."
        }
        return .result(value: shouldOpen, dialog: dialog)
    }
}

/// Met à jour la température mesurée chez vous — par exemple envoyée par un
/// capteur connecté (HomeKit, Matter) via une automatisation Raccourcis.
struct SetIndoorTemperatureIntent: AppIntent {
    static let title: LocalizedStringResource = "Indiquer la température chez vous"
    static let description = IntentDescription(
        "Met à jour la température de votre logement, par exemple depuis un capteur connecté.",
        categoryName: "Réglages"
    )

    @Parameter(title: "Température (°C)", inclusiveRange: (8, 45))
    var temperature: Double

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Même pas que le curseur de l'app : demi-degré, borné 8–45 °C.
        let clamped = (min(45, max(8, temperature)) * 2).rounded() / 2
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
        return .result(dialog: "C’est noté : il fait \(clamped.degreesText) chez vous.")
    }
}

struct NadirAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetVerdictIntent(),
            phrases: [
                "Le conseil \(.applicationName)",
                "Le verdict \(.applicationName)",
                "Demande le conseil à \(.applicationName)",
                "Quand ouvrir les fenêtres avec \(.applicationName)",
                "Quand aérer avec \(.applicationName)",
            ],
            shortTitle: "Le conseil",
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
