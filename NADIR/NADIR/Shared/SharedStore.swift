import Foundation

/// Pont app ↔ widgets (App Group) : profil et météo partagés, pour que les
/// widgets recalculent exactement la même courbe que l'app.
enum SharedStore {
    static let appGroup = "group.com.solalgendrin.nadir"
    private static let seriesKey = "nadir.shared.series.v1"

    /// Retombe sur le stockage local si l'App Group est indisponible.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func save(series: WeatherSeries) {
        guard let data = try? JSONEncoder().encode(series) else { return }
        defaults.set(data, forKey: seriesKey)
    }

    static func loadSeries() -> WeatherSeries? {
        guard let data = defaults.data(forKey: seriesKey) else { return nil }
        return try? JSONDecoder().decode(WeatherSeries.self, from: data)
    }
}
