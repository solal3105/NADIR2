import Foundation

/// Série météo horaire pour un lieu : températures extérieures et points de rosée.
struct WeatherSeries: Equatable {
    var times: [Date]
    var outdoor: [Double]
    var dewPoint: [Double]
    var place: String
    var timeZone: TimeZone
    var isDemo: Bool

    var count: Int { times.count }

    /// Fenêtre de simulation : démarre à l'heure courante (incluse) et couvre
    /// jusqu'à 30 h, pour inclure le pic de demain après-midi — celui que la
    /// nuit peut encore aider.
    func window(from now: Date = .now, maxHours: Int = 30) -> WeatherSeries {
        var i0 = times.firstIndex(where: { $0 >= now }) ?? 0
        i0 = max(0, i0 - 1)
        let n = min(maxHours, times.count - i0)
        guard n > 0 else { return self }
        return WeatherSeries(
            times: Array(times[i0 ..< i0 + n]),
            outdoor: Array(outdoor[i0 ..< i0 + n]),
            dewPoint: Array(dewPoint[i0 ..< i0 + n]),
            place: place,
            timeZone: timeZone,
            isDemo: isDemo
        )
    }

    /// Heure locale du lieu (0–23) pour un index de la série.
    func hour(at index: Int) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.component(.hour, from: times[index])
    }

    /// Étiquette d'heure façon « 06h », dans le fuseau du lieu.
    func hourLabel(at index: Int) -> String {
        String(format: "%02dh", hour(at: index))
    }

    /// Série de démonstration : sinusoïde réaliste (min vers 5 h, max vers 17 h),
    /// affichée tant qu'aucune météo réelle n'est chargée.
    static func demo(now: Date = .now) -> WeatherSeries {
        let calendar = Calendar.current
        let anchor = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        var times: [Date] = []
        var temps: [Double] = []
        for k in -1 ..< 33 {
            let date = anchor.addingTimeInterval(Double(k) * 3600)
            let h = Double(calendar.component(.hour, from: date))
            let t = 26 - 8 * cos(2 * .pi * (h - 5) / 24)
            times.append(date)
            temps.append((t * 10).rounded() / 10)
        }
        return WeatherSeries(
            times: times,
            outdoor: temps,
            dewPoint: Array(repeating: 12, count: times.count),
            place: "Exemple",
            timeZone: .current,
            isDemo: true
        )
    }
}

/// Partageable avec les widgets (le fuseau voyage par son identifiant).
extension WeatherSeries: Codable {
    private enum CodingKeys: String, CodingKey {
        case times, outdoor, dewPoint, place, timeZoneIdentifier, isDemo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        times = try container.decode([Date].self, forKey: .times)
        outdoor = try container.decode([Double].self, forKey: .outdoor)
        dewPoint = try container.decode([Double].self, forKey: .dewPoint)
        place = try container.decode(String.self, forKey: .place)
        timeZone = TimeZone(identifier: try container.decode(String.self, forKey: .timeZoneIdentifier))
            ?? .current
        isDemo = try container.decode(Bool.self, forKey: .isDemo)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(times, forKey: .times)
        try container.encode(outdoor, forKey: .outdoor)
        try container.encode(dewPoint, forKey: .dewPoint)
        try container.encode(place, forKey: .place)
        try container.encode(timeZone.identifier, forKey: .timeZoneIdentifier)
        try container.encode(isDemo, forKey: .isDemo)
    }
}
