import Foundation

/// La série météo pour les surfaces hors app (widgets, raccourcis Siri) :
/// celle partagée si elle couvre encore les 30 h à venir, sinon
/// re-téléchargée depuis Open-Meteo puis repartagée.
enum SeriesProvider {
    static func current(profile: UserProfile) async -> WeatherSeries {
        let saved = SharedStore.loadSeries()
        let horizon = Date.now.addingTimeInterval(30 * 3600)
        if let saved, let last = saved.times.last, last >= horizon { return saved }

        if let latitude = profile.latitude, let longitude = profile.longitude {
            let place = saved?.place ?? (profile.place.isEmpty ? "Votre logement" : profile.place)
            if let fetched = try? await WeatherService().forecast(
                latitude: latitude, longitude: longitude, placeName: place
            ) {
                SharedStore.save(series: fetched)
                return fetched
            }
        }
        return saved ?? .demo()
    }

    /// L'analyse du moment, avec les réglages persistés.
    static func currentAdvice(profile: UserProfile) async -> Advice {
        let series = await current(profile: profile)
        return Advice(series: series, profile: profile)
    }
}

/// Le conseil complet à une date : la simulation, et en mode aérer
/// (mi-saison) le créneau d'aération. Partagé par l'app, les widgets et Siri.
struct Advice {
    let analysis: ThermalAnalysis
    let aeration: AerationAnalysis?

    init(series: WeatherSeries, profile: UserProfile, at date: Date = .now) {
        let window = series.window(from: date)
        let isAiring = AerationAnalysis.resolve(profile.mode, series: window) == .air
        analysis = ThermalAnalysis(
            series: window,
            indoorNow: profile.indoorNow,
            inertia: profile.inertia,
            ventilation: profile.ventilation,
            exposure: profile.exposure,
            keepClosed: isAiring
        )
        aeration = isAiring
            ? AerationAnalysis(
                series: window,
                indoorNow: profile.indoorNow,
                inertia: profile.inertia,
                ventilation: profile.ventilation,
                exposure: profile.exposure
            )
            : nil
    }

    var verdictTitle: String { aeration?.verdictTitle ?? analysis.verdictTitle }

    /// Le créneau du moment : ouvrir / fermer, ou aérer / refermer.
    var window: (start: Date, end: Date)? { aeration?.airing ?? analysis.firstWindow }

    var shouldOpenNow: Bool { aeration?.isNow ?? analysis.shouldOpenNow }
}
