import Foundation

/// Inertie thermique des murs — capacité interne surfacique d'après EN ISO 13790.
enum WallInertia: String, CaseIterable, Identifiable, Codable {
    case light, medium, heavy

    var id: Self { self }

    /// Capacité interne, J/(m²·K).
    var kappa: Double {
        switch self {
        case .light: 110_000
        case .medium: 165_000
        case .heavy: 260_000
        }
    }

    var label: String {
        switch self {
        case .light: "légers"
        case .medium: "moyens"
        case .heavy: "lourds"
        }
    }
}

/// Intensité de la ventilation fenêtres ouvertes, en renouvellements d'air par heure.
enum Ventilation: String, CaseIterable, Identifiable, Codable {
    case low, medium, high

    var id: Self { self }

    /// Renouvellements d'air par heure, fenêtre ouverte.
    var airChangesPerHour: Double {
        switch self {
        case .low: 3
        case .medium: 8
        case .high: 15
        }
    }

    var label: String {
        switch self {
        case .low: "faible"
        case .medium: "moyenne"
        case .high: "forte"
        }
    }
}
