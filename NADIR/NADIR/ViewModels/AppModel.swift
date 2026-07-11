import Foundation
import Observation
import WidgetKit

/// État central de l'app : profil, météo, simulation, statuts et notifications.
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
    /// Vrai dès qu'une mesure du capteur lié est arrivée cette session :
    /// distingue « synchronisé » d'un lien mort (capteur retiré, accès révoqué).
    private(set) var sensorActive = false
    /// Curseur en cours de glissement : les mesures du capteur attendent
    /// la fin du geste au lieu de faire sauter le pouce sous le doigt.
    private var isAdjustingIndoor = false
    private var pendingSensorValue: Double?
    var series: WeatherSeries
    var status = ""
    /// Géolocalisation en cours — anime le viseur.
    private(set) var isLocating = false
    /// « Maintenant » observé : rafraîchi au retour au premier plan pour que
    /// la fenêtre de simulation et les notifications suivent l'heure réelle.
    var now: Date = .now

    /// Change à chaque nouvelle source météo : rejoue l'animation du graphe.
    private(set) var chartAnimationKey = 0
    /// Dernière source dont l'animation a été jouée — un retour d'onglet
    /// ne la rejoue pas.
    var animatedChartKey = -1

    private let weather = WeatherService()
    private let location = LocationService()
    private let notifications = NotificationScheduler()
    /// Le gestionnaire HomeKit sous-jacent n'est créé qu'à la demande :
    /// au lancement seulement si un capteur est déjà lié.
    let homeKit = HomeKitService()
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
        notifications.cancel(.open)
        notifications.cancel(.close)
        syncNotifications()

        Self.shared = self

        homeKit.onReading = { [weak self] id, value in
            self?.adoptSensorReading(id: id, value: value)
        }
        if let sensorID = profile.sensorID {
            homeKit.monitor(sensorID: sensorID)
        }
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
        syncNotifications()
        // Le capteur lié a pu changer de valeur pendant l'absence.
        homeKit.readNow()
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

    func setAdjustingIndoor(_ adjusting: Bool) {
        isAdjustingIndoor = adjusting
        guard !adjusting, let pending = pendingSensorValue else { return }
        pendingSensorValue = nil
        if pending != indoorNow { setIndoor(pending) }
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

    // MARK: - Capteur connecté

    var sensorLinked: Bool {
        profile.sensorID != nil
    }

    func linkSensor(_ sensor: HomeKitService.Sensor) {
        // Re-lier le capteur déjà lié ne remet pas son état en cause.
        if profile.sensorID != sensor.id { sensorActive = false }
        profile.sensorID = sensor.id
        profile.sensorName = sensor.name
        persist()
        homeKit.monitor(sensorID: sensor.id)
    }

    func unlinkSensor() {
        homeKit.stopMonitoring()
        profile.sensorID = nil
        profile.sensorName = ""
        sensorActive = false
        pendingSensorValue = nil
        persist()
    }

    private func adoptSensorReading(id: UUID, value: Double) {
        guard id == profile.sensorID else { return }
        sensorActive = true
        // Même pas que le curseur : demi-degré, borné 20 à 34 °C.
        let clamped = (min(34, max(20, value)) * 2).rounded() / 2
        if isAdjustingIndoor {
            pendingSensorValue = clamped
            return
        }
        guard clamped != indoorNow else { return }
        setIndoor(clamped)
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

    // MARK: - Notifications

    struct NotificationWindow {
        var start: Date
        var end: Date
        var startIsPast: Bool
    }

    /// Le créneau à notifier : seulement tant qu'il n'est pas fini,
    /// jugé sur la même horloge (`now`) que tout le reste de l'état.
    var notificationWindow: NotificationWindow? {
        guard let window = analysis.firstWindow, window.end > now else { return nil }
        return NotificationWindow(start: window.start, end: window.end, startIsPast: window.start <= now)
    }

    func toggleNotification(_ kind: NotificationScheduler.Kind) async {
        let isEnabling = switch kind {
        case .open: !profile.notifyOnOpen
        case .close: !profile.notifyOnClose
        }
        if isEnabling {
            guard await notifications.requestAuthorization() else {
                setStatus("Notifications refusées. Autorisez-les dans Réglages.", in: .main)
                return
            }
            if status.hasPrefix("Notifications refusées") { setStatus("", in: .main) }
        }
        switch kind {
        case .open: profile.notifyOnOpen = isEnabling
        case .close: profile.notifyOnClose = isEnabling
        }
        persist()
    }

    /// Aligne les notifications programmées sur le créneau courant :
    /// ne replanifie que si l'heure visée a changé. Une notification ne
    /// vaut que pour son créneau : l'heure passée, le réglage s'éteint
    /// au lieu de se réarmer en silence sur le créneau suivant.
    func syncNotifications() {
        expirePastNotifications()
        let window = analysis.firstWindow
        let openTarget: Date? = (profile.notifyOnOpen && window.map { $0.start > now } == true)
            ? window?.start : nil
        let closeTarget: Date? = (profile.notifyOnClose && window.map { $0.end > now } == true)
            ? window?.end : nil

        if openTarget != scheduledOpen {
            if let openTarget { notifications.schedule(.open, at: openTarget) } else { notifications.cancel(.open) }
            scheduledOpen = openTarget
        }
        if closeTarget != scheduledClose {
            if let closeTarget { notifications.schedule(.close, at: closeTarget) } else { notifications.cancel(.close) }
            scheduledClose = closeTarget
        }
        rememberNotificationTargets(open: openTarget, close: closeTarget)
    }

    /// L'heure visée est mémorisée sur disque : au retour dans l'app, une
    /// notification déjà partie éteint son interrupteur, même après relance.
    private func expirePastNotifications() {
        var changed = false
        if profile.notifyOnOpen, let armed = profile.notifyOpenTarget, armed <= now {
            profile.notifyOnOpen = false
            profile.notifyOpenTarget = nil
            changed = true
        }
        if profile.notifyOnClose, let armed = profile.notifyCloseTarget, armed <= now {
            profile.notifyOnClose = false
            profile.notifyCloseTarget = nil
            changed = true
        }
        if changed { profile.save() }
    }

    private func rememberNotificationTargets(open: Date?, close: Date?) {
        var changed = false
        if profile.notifyOnOpen {
            if let open, profile.notifyOpenTarget != open {
                profile.notifyOpenTarget = open
                changed = true
            }
        } else if profile.notifyOpenTarget != nil {
            profile.notifyOpenTarget = nil
            changed = true
        }
        if profile.notifyOnClose {
            if let close, profile.notifyCloseTarget != close {
                profile.notifyCloseTarget = close
                changed = true
            }
        } else if profile.notifyCloseTarget != nil {
            profile.notifyCloseTarget = nil
            changed = true
        }
        if changed { profile.save() }
    }

    // MARK: - Privé

    private func adopt(_ newSeries: WeatherSeries) {
        chartAnimationKey += 1
        series = newSeries
        now = .now
        if !newSeries.isDemo { SharedStore.save(series: newSeries) }
        syncNotifications()
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
        syncNotifications()
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
