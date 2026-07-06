import Foundation

struct GeocodedPlace: Equatable {
    var name: String
    var latitude: Double
    var longitude: Double
}

enum WeatherServiceError: LocalizedError {
    case cityNotFound
    case badResponse

    var errorDescription: String? {
        switch self {
        case .cityNotFound: "Ville introuvable. Vérifiez l'orthographe."
        case .badResponse: "Météo indisponible pour le moment."
        }
    }
}

/// Client Open-Meteo : géocodage de ville et prévisions horaires
/// (température et point de rosée sur 3 jours, fuseau du lieu).
struct WeatherService {
    /// Timeout court : les raccourcis Siri et les widgets ont un budget
    /// d'exécution de quelques secondes — mieux vaut retomber sur la série
    /// sauvegardée que pendre sur un réseau lent.
    private static let shortTimeoutSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 8
        configuration.timeoutIntervalForResource = 15
        return URLSession(configuration: configuration)
    }()

    var session: URLSession = WeatherService.shortTimeoutSession

    func geocode(city: String) async throws -> GeocodedPlace {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: city),
            URLQueryItem(name: "count", value: "1"),
            URLQueryItem(name: "language", value: "fr"),
            URLQueryItem(name: "format", value: "json"),
        ]
        let response: GeocodingResponse = try await get(components.url!)
        guard let result = response.results?.first else {
            throw WeatherServiceError.cityNotFound
        }
        var name = result.name
        if let country = result.countryCode { name += " (\(country))" }
        return GeocodedPlace(name: name, latitude: result.latitude, longitude: result.longitude)
    }

    func forecast(latitude: Double, longitude: Double, placeName: String) async throws -> WeatherSeries {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(latitude)),
            URLQueryItem(name: "longitude", value: String(longitude)),
            URLQueryItem(name: "hourly", value: "temperature_2m,dew_point_2m"),
            URLQueryItem(name: "forecast_days", value: "3"),
            URLQueryItem(name: "timezone", value: "auto"),
        ]
        let response: ForecastResponse = try await get(components.url!)
        let timeZone = TimeZone(identifier: response.timezone) ?? .current

        // Les heures sont renvoyées en heure locale du lieu, sans décalage
        // (« 2026-07-06T14:00 ») : on les interprète dans son fuseau.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"

        var times: [Date] = []
        var outdoor: [Double] = []
        var dewPoint: [Double] = []
        let hourly = response.hourly
        for (i, stamp) in hourly.time.enumerated() {
            guard i < hourly.temperature2m.count, i < hourly.dewPoint2m.count,
                  let date = formatter.date(from: stamp),
                  let temperature = hourly.temperature2m[i],
                  let dew = hourly.dewPoint2m[i]
            else { continue }
            times.append(date)
            outdoor.append(temperature)
            dewPoint.append(dew)
        }
        guard !times.isEmpty else { throw WeatherServiceError.badResponse }
        return WeatherSeries(
            times: times, outdoor: outdoor, dewPoint: dewPoint,
            place: placeName, timeZone: timeZone, isDemo: false
        )
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw WeatherServiceError.badResponse
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

private struct GeocodingResponse: Decodable {
    struct Result: Decodable {
        var name: String
        var latitude: Double
        var longitude: Double
        var countryCode: String?

        enum CodingKeys: String, CodingKey {
            case name, latitude, longitude
            case countryCode = "country_code"
        }
    }

    var results: [Result]?
}

private struct ForecastResponse: Decodable {
    struct Hourly: Decodable {
        var time: [String]
        var temperature2m: [Double?]
        var dewPoint2m: [Double?]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case dewPoint2m = "dew_point_2m"
        }
    }

    var timezone: String
    var hourly: Hourly
}
