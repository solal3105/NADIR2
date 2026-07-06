import Foundation

/// Profil de l'utilisateur, persisté entre les lancements et partagé avec
/// les widgets via l'App Group.
struct UserProfile: Equatable {
    var onboarded = false
    var inertia: WallInertia = .medium
    var ventilation: Ventilation = .medium
    var exposure: Exposure = .default
    var indoorNow: Double = 26
    var latitude: Double?
    var longitude: Double?
    var place = ""
    var alarmOnOpen = false
    var alarmOnClose = false

    private static let storageKey = "nadir.profile.v1"

    static func load() -> UserProfile {
        if let data = SharedStore.defaults.data(forKey: storageKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return profile
        }
        // Migration depuis l'ancien stockage local de l'app.
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile.save()
            return profile
        }
        return UserProfile()
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        SharedStore.defaults.set(data, forKey: Self.storageKey)
    }
}

/// Décodage tolérant : chaque champ manquant retombe sur sa valeur par
/// défaut — un profil enregistré par une version précédente reste valide.
extension UserProfile: Codable {
    private enum CodingKeys: String, CodingKey {
        case onboarded, inertia, ventilation, exposure, indoorNow
        case latitude, longitude, place, alarmOnOpen, alarmOnClose
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        onboarded = try container.decodeIfPresent(Bool.self, forKey: .onboarded) ?? false
        inertia = try container.decodeIfPresent(WallInertia.self, forKey: .inertia) ?? .medium
        ventilation = try container.decodeIfPresent(Ventilation.self, forKey: .ventilation) ?? .medium
        exposure = try container.decodeIfPresent(Exposure.self, forKey: .exposure) ?? .default
        indoorNow = try container.decodeIfPresent(Double.self, forKey: .indoorNow) ?? 26
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        place = try container.decodeIfPresent(String.self, forKey: .place) ?? ""
        alarmOnOpen = try container.decodeIfPresent(Bool.self, forKey: .alarmOnOpen) ?? false
        alarmOnClose = try container.decodeIfPresent(Bool.self, forKey: .alarmOnClose) ?? false
    }
}
