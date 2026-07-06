import Foundation
import Observation
import WidgetKit

/// État central de l'app : profil, météo, simulation, statuts et alarmes.
@MainActor
@Observable
final class AppModel {
    /// L'instance vivante, pour que les raccourcis Siri (exécutés dans le
    /// même process) passent par l'état en mémoire plutôt que par le disque.
    private(set) static weak var shared: AppModel?

    enum Tab: Hashable {
        case today, guide, learn, about
    }

    enum Context {
        case main, onboarding
    }

    var tab: Tab = .today

    var showOnboarding: Bool
    var onboardingStep = 0
    var onboardingStatus = ""

    var profile: UserProfile
    /// Température saisie par l'utilisateur — mémorisée entre les sessions.
    var indoorNow: Double = 26
    var series: WeatherSeries
    var status = ""
    /// Géolocalisation en cours — anime le viseur.
    private(set) var isLocating = false
    /// « Maintenant » observé : rafraîchi au retour au premier plan pour que
    /// la fenêtre de simulation et les alarmes suivent l'heure réelle.
    var now: Date = .now

    /// Change à chaque nouvelle source météo : rejoue l'animation du graphe.
    private(set) var chartAnimationKey = 0
    /// Dernière source dont l'animation a été jouée — un retour d'onglet
    /// ne la rejoue pas.
    var animatedChartKey = -1

    private let weather = WeatherService()
    private let location = LocationService()
    private let alarms = AlarmScheduler()
    private var scheduledOpen: Date?
    private var scheduledClose: Date?
    private var widgetReloadTask: Task<Void, Never>?

    init() {
        let profile = UserProfile.load()
        self.profile = profile
        self.showOnboarding = !profile.onboarded
        self.indoorNow = profile.indoorNow
        self.series = SharedStore.loadSeries() ?? .demo()

        // Les notifications d'un lancement précédent survivent au force-quit :
        // on repart de zéro puis on replanifie selon le créneau courant.
        alarms.cancel(.open)
        alarms.cancel(.close)
        syncAlarms()

        Self.shared = self
    }

    var analysis: ThermalAnalysis {
        ThermalAnalysis(
            series: series.window(from: now),
            indoorNow: indoorNow,
            inertia: profile.inertia,
            ventilation: profile.ventilation,
            exposure: profile.exposure
        )
    }

    // MARK: - Cycle de vie

    /// Au lancement : recharge la météo du lieu mémorisé, sinon l'exemple.
    func start() async {
        guard let latitude = profile.latitude, let longitude = profile.longitude else { return }
        let place = profile.place.isEmpty ? "Votre logement" : profile.place
        setStatus("Récupération de la météo…", in: .main)
        do {
            adopt(try await weather.forecast(latitude: latitude, longitude: longitude, placeName: place))
            setStatus("", in: .main)
        } catch {
            setStatus("Météo indisponible.", in: .main)
        }
    }

    func refreshNow() {
        now = .now
        // Un raccourci Siri a pu modifier le profil pendant que l'app
        // était en arrière-plan : le disque fait foi.
        let stored = UserProfile.load()
        if stored != profile {
            profile = stored
            indoorNow = stored.indoorNow
        }
        syncAlarms()
    }

    // MARK: - Localisation & météo

    func useMyLocation(in context: Context) async {
        isLocating = true
        defer { isLocating = false }
        setStatus("Localisation en cours…", in: context)
        do {
            let coordinate = try await location.currentCoordinate()
            setStatus("Récupération de la météo…", in: context)
            let city = await location.cityName(for: coordinate)
            let series = try await weather.forecast(
                latitude: coordinate.latitude, longitude: coordinate.longitude,
                placeName: city ?? "Votre position"
            )
            adopt(series)
            persistPlace(latitude: coordinate.latitude, longitude: coordinate.longitude)
            setStatus("", in: context)
            if context == .onboarding { advanceOnboarding() }
        } catch let error as LocationServiceError {
            setStatus(error.localizedDescription, in: context)
        } catch {
            setStatus("Météo indisponible.", in: context)
        }
    }

    func search(city: String, in context: Context) async {
        let city = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !city.isEmpty else {
            if context == .onboarding { advanceOnboarding() }
            return
        }
        setStatus("Recherche de « \(city) »…", in: context)
        do {
            let place = try await weather.geocode(city: city)
            setStatus("Récupération de la météo…", in: context)
            let series = try await weather.forecast(
                latitude: place.latitude, longitude: place.longitude, placeName: place.name
            )
            adopt(series)
            persistPlace(latitude: place.latitude, longitude: place.longitude)
            setStatus("", in: context)
            if context == .onboarding { advanceOnboarding() }
        } catch WeatherServiceError.cityNotFound {
            setStatus(
                context == .onboarding
                    ? "Ville introuvable. Vérifiez l'orthographe, ou continuez sans ville."
                    : "Ville introuvable. Vérifiez l'orthographe.",
                in: context
            )
        } catch {
            setStatus(
                context == .onboarding
                    ? "Connexion impossible. Réessayez, ou continuez sans ville."
                    : "Connexion impossible. Réessayez dans un instant.",
                in: context
            )
        }
    }

    // MARK: - Réglages

    func setIndoor(_ value: Double) {
        indoorNow = value
        profile.indoorNow = value
        persist()
    }

    func set(inertia: WallInertia) {
        profile.inertia = inertia
        persist()
    }

    func set(ventilation: Ventilation) {
        profile.ventilation = ventilation
        persist()
    }

    func toggleExposure(_ facade: Facade) {
        profile.exposure.toggle(facade)
        persist()
    }

    // MARK: - Onboarding

    func advanceOnboarding() {
        onboardingStep = min(3, onboardingStep + 1)
        onboardingStatus = ""
    }

    func backOnboarding() {
        onboardingStep = max(0, onboardingStep - 1)
        onboardingStatus = ""
    }

    func finishOnboarding() {
        showOnboarding = false
        profile.onboarded = true
        persist()
    }

    /// Rejoue l'introduction depuis le début (réglages conservés).
    func replayOnboarding() {
        onboardingStep = 0
        onboardingStatus = ""
        tab = .today
        showOnboarding = true
    }

    // MARK: - Alarmes

    struct AlarmWindow {
        var start: Date
        var end: Date
        var startIsPast: Bool
    }

    /// Le créneau à alarmer — seulement tant qu'il n'est pas fini,
    /// jugé sur la même horloge (`now`) que tout le reste de l'état.
    var alarmWindow: AlarmWindow? {
        guard let window = analysis.firstWindow, window.end > now else { return nil }
        return AlarmWindow(start: window.start, end: window.end, startIsPast: window.start <= now)
    }

    func toggleAlarm(_ kind: AlarmScheduler.Kind) async {
        let isEnabling = switch kind {
        case .open: !profile.alarmOnOpen
        case .close: !profile.alarmOnClose
        }
        if isEnabling {
            guard await alarms.requestAuthorization() else {
                setStatus("Notifications refusées. Autorisez-les dans Réglages pour les alarmes.", in: .main)
                return
            }
            if status.hasPrefix("Notifications refusées") { setStatus("", in: .main) }
        }
        switch kind {
        case .open: profile.alarmOnOpen = isEnabling
        case .close: profile.alarmOnClose = isEnabling
        }
        persist()
    }

    /// Aligne les notifications programmées sur le créneau courant :
    /// ne replanifie que si l'heure visée a changé.
    func syncAlarms() {
        let window = analysis.firstWindow
        let openTarget: Date? = (profile.alarmOnOpen && window.map { $0.start > now } == true)
            ? window?.start : nil
        let closeTarget: Date? = (profile.alarmOnClose && window.map { $0.end > now } == true)
            ? window?.end : nil

        if openTarget != scheduledOpen {
            if let openTarget { alarms.schedule(.open, at: openTarget) } else { alarms.cancel(.open) }
            scheduledOpen = openTarget
        }
        if closeTarget != scheduledClose {
            if let closeTarget { alarms.schedule(.close, at: closeTarget) } else { alarms.cancel(.close) }
            scheduledClose = closeTarget
        }
    }

    // MARK: - Privé

    private func adopt(_ newSeries: WeatherSeries) {
        chartAnimationKey += 1
        series = newSeries
        now = .now
        if !newSeries.isDemo { SharedStore.save(series: newSeries) }
        syncAlarms()
        scheduleWidgetReload()
    }

    private func persistPlace(latitude: Double, longitude: Double) {
        profile.latitude = latitude
        profile.longitude = longitude
        profile.place = series.place
        persist()
    }

    private func persist() {
        profile.save()
        syncAlarms()
        scheduleWidgetReload()
    }

    /// Les widgets recalculent la courbe depuis les données partagées ;
    /// un court débounce évite de les recharger à chaque cran de curseur.
    private func scheduleWidgetReload() {
        widgetReloadTask?.cancel()
        widgetReloadTask = Task {
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    private func setStatus(_ message: String, in context: Context) {
        switch context {
        case .main: status = message
        case .onboarding: onboardingStatus = message
        }
    }
}

// MARK: - Formats d'affichage

extension AppModel {
    /// « 26 °C » ou « 26,5 °C ».
    var indoorLabel: String {
        let value = indoorNow.truncatingRemainder(dividingBy: 1) == 0
            ? indoorNow.noDecimal : indoorNow.oneDecimal
        return "\(value) °C"
    }

    /// « 06:12 » dans le fuseau du lieu.
    func clockLabel(for date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = series.timeZone
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", parts.hour ?? 0, parts.minute ?? 0)
    }

    /// « Dans 45 min », « Dans 3 h 05 » ou « Dans 3 h ».
    func delayLabel(until date: Date) -> String {
        let minutes = max(0, Int((date.timeIntervalSince(now) / 60).rounded()))
        guard minutes >= 60 else { return "Dans \(minutes) min" }
        let hours = minutes / 60
        let rest = minutes % 60
        return rest > 0 ? "Dans \(hours) h \(String(format: "%02d", rest))" : "Dans \(hours) h"
    }
}
