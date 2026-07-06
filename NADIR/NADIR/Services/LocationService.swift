import CoreLocation

enum LocationServiceError: LocalizedError {
    case denied
    case unavailable

    var errorDescription: String? {
        switch self {
        case .denied: "Localisation refusée. Tapez votre ville."
        case .unavailable: "Position introuvable. Tapez votre ville."
        }
    }
}

/// Une position, à la demande : gère l'autorisation puis livre la première
/// localisation reçue.
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Nom de la ville au point donné (géocodage inverse) — affiché à la
    /// place de « Votre position ».
    func cityName(for coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location)
        return placemarks?.first?.locality
    }

    func currentCoordinate() async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            // Une seule requête à la fois : un nouvel appel évince proprement
            // celui en attente au lieu de laisser sa Task suspendue à jamais.
            resume(throwing: LocationServiceError.unavailable)
            self.continuation = continuation
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                resume(throwing: LocationServiceError.denied)
            default:
                manager.requestLocation()
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard continuation != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            resume(throwing: LocationServiceError.denied)
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            resume(throwing: LocationServiceError.unavailable)
            return
        }
        resume(returning: location.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .denied {
            resume(throwing: LocationServiceError.denied)
        } else {
            resume(throwing: LocationServiceError.unavailable)
        }
    }

    private func resume(returning coordinate: CLLocationCoordinate2D) {
        continuation?.resume(returning: coordinate)
        continuation = nil
    }

    private func resume(throwing error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
