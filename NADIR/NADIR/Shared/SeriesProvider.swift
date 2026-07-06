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
    static func currentAnalysis(profile: UserProfile) async -> ThermalAnalysis {
        let series = await current(profile: profile)
        return ThermalAnalysis(
            series: series.window(),
            indoorNow: profile.indoorNow,
            inertia: profile.inertia,
            ventilation: profile.ventilation,
            exposure: profile.exposure
        )
    }
}
