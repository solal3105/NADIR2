import Foundation

/// Façade d'exposition du logement : détermine l'apport solaire horaire.
enum Facade: String, CaseIterable, Identifiable, Codable {
    case north, east, south, west

    var id: Self { self }

    var label: String {
        switch self {
        case .north: "nord"
        case .east: "est"
        case .south: "sud"
        case .west: "ouest"
        }
    }

    var titleLabel: String {
        switch self {
        case .north: "Nord"
        case .east: "Est"
        case .south: "Sud"
        case .west: "Ouest"
        }
    }

    var opposite: Facade {
        switch self {
        case .north: .south
        case .south: .north
        case .east: .west
        case .west: .east
        }
    }

    /// Heure du pic de soleil direct sur cette façade (nil : jamais de direct).
    var solarPeakHour: Double? {
        switch self {
        case .north: nil
        case .east: 9
        case .south: 13
        case .west: 17.5
        }
    }

    /// Demi-largeur de la cloche solaire, en heures.
    var solarWidth: Double {
        switch self {
        case .north: 0
        case .east: 4
        case .south: 4.5
        case .west: 4.5
        }
    }
}

/// Une ou deux façades exposées — deux si le logement est traversant.
struct Exposure: Equatable, Codable {
    var primary: Facade
    var secondary: Facade?

    static let `default` = Exposure(primary: .south)

    /// Logement traversant : deux façades distinctes.
    var isDual: Bool { secondary != nil && secondary != primary }

    var facades: [Facade] {
        isDual ? [primary, secondary!] : [primary]
    }

    /// Façades opposées : le courant d'air traverse de part en part.
    var isCrossOpposite: Bool { isDual && secondary == primary.opposite }

    func contains(_ facade: Facade) -> Bool { facades.contains(facade) }

    var label: String {
        isDual ? "\(primary.titleLabel) + \(secondary!.titleLabel)" : primary.titleLabel
    }

    /// Coche/décoche une façade : jamais zéro sélection, deux au maximum
    /// (la plus ancienne est évincée).
    mutating func toggle(_ facade: Facade) {
        var selection = facades
        if let index = selection.firstIndex(of: facade) {
            if selection.count > 1 { selection.remove(at: index) }
        } else {
            selection.append(facade)
            if selection.count > 2 { selection.removeFirst() }
        }
        primary = selection[0]
        secondary = selection.count > 1 ? selection[1] : nil
    }
}
