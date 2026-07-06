import Foundation

/// Modèle thermique deux nœuds (air + masse), pas horaire.
///
/// La ventilation refroidit vite l'AIR ; l'air refroidit lentement la MASSE
/// selon son inertie. L'ouverture des fenêtres est pilotée par l'écart de
/// température avec hystérésis (on ouvre sous −0,75 °C d'écart, on referme
/// au-dessus de −0,25 °C), corrigé d'une pénalité solaire : ouvrir n'a
/// d'intérêt que si le refroidissement par l'air dépasse le soleil
/// supplémentaire admis fenêtre ouverte (volets relevés).
///
/// Hypothèses : pièce type de 20 m² / 50 m³, apports internes de 150 W,
/// soleil direct de 650 W par façade exposée + 120 W de diffus, volets
/// fermés laissant passer 30 % du soleil. Capacités thermiques d'après
/// EN ISO 13790. À titre indicatif.
enum ThermalModel {
    static let floorArea: Double = 20        // m²
    static let volume: Double = 50           // m³
    static let airHeatCapacityPerVolume: Double = 1206   // ρ·cp de l'air, J/(m³·K)
    static let airNodeCapacity: Double = 150_000         // J/K : air + mobilier léger
    static let airMassCoupling: Double = 300 // W/K
    static let envelopeLoss: Double = 50     // W/K : enveloppe + infiltration
    static let internalGains: Double = 150   // W : occupants + appareils
    static let directSolar: Double = 650     // W : pic de direct sur une façade
    static let diffuseSolar: Double = 120    // W : pic de diffus, toutes façades
    static let shadeFactor: Double = 0.3     // part du soleil passant les volets fermés
    static let substeps = 10                 // sous-pas horaires (stabilité numérique)
    static let openThreshold: Double = 0.75  // °C sous l'intérieur pour ouvrir
    static let closeThreshold: Double = 0.25 // °C sous l'intérieur pour refermer

    struct Result: Equatable {
        /// Température de l'air intérieur à chaque heure de la série.
        var indoor: [Double]
        /// Fenêtres ouvertes (conseillées) à chaque heure de la série.
        var isOpen: [Bool]
    }

    /// Apport solaire à une heure donnée : composante directe sur chaque
    /// façade (pic 9 h à l'est, 13 h au sud, 17 h 30 à l'ouest, rien au
    /// nord) + diffus pour tous. En double exposition le vitrage se répartit
    /// (~0,6× par façade) et le diffus augmente (logement d'angle).
    static func solarGains(hour: Int, exposure: Exposure) -> Double {
        let h = Double(hour)
        let perFace = exposure.isDual ? 0.6 : 1.0
        var gains = diffuseSolar * (exposure.isDual ? 1.2 : 1) * bell(h, peak: 13.5, width: 7.5)
        for facade in exposure.facades {
            guard let peak = facade.solarPeakHour else { continue }
            gains += directSolar * perFace * bell(h, peak: peak, width: facade.solarWidth)
        }
        return gains
    }

    /// Simule la température intérieure sur la série météo donnée.
    ///
    /// L'état initial de la masse est DÉDUIT de la température saisie par
    /// l'utilisateur, en résolvant l'équilibre de l'air à t = 0 fenêtres
    /// fermées (dTa/dt = 0) : la courbe démarre exactement à la température
    /// saisie, sans saut artificiel.
    static func simulate(
        series: WeatherSeries,
        indoorNow: Double,
        inertia: WallInertia,
        ventilation: Ventilation,
        exposure: Exposure
    ) -> Result {
        let n = series.outdoor.count
        guard n > 0 else { return Result(indoor: [], isOpen: []) }

        // Logement traversant : courant d'air maximal si façades opposées,
        // et deux murs extérieurs qui échangent un peu plus.
        let crossMultiplier = exposure.isDual ? (exposure.isCrossOpposite ? 1.8 : 1.5) : 1.0
        let envelope = envelopeLoss * (exposure.isDual ? 1.15 : 1)
        let massCapacity = inertia.kappa * floorArea
        let ventilationConductance =
            airHeatCapacityPerVolume * ventilation.airChangesPerHour * crossMultiplier * volume / 3600
        let dt = 3600.0 / Double(substeps)

        let initialGains = internalGains
            + shadeFactor * solarGains(hour: series.hour(at: 0), exposure: exposure)
        var airTemp = indoorNow
        var massTemp = indoorNow
            - (envelope * (series.outdoor[0] - indoorNow) + initialGains) / airMassCoupling

        var isOpen = false
        var indoor = [airTemp]
        var open: [Bool] = []

        for i in 0 ..< n {
            let solar = solarGains(hour: series.hour(at: i), exposure: exposure)
            // Ouvrir n'a d'intérêt que si le refroidissement par l'air dépasse
            // le soleil supplémentaire admis fenêtre ouverte : pénalité
            // exprimée en degrés équivalents.
            let solarPenalty = (1 - shadeFactor) * solar / ventilationConductance
            if isOpen {
                if series.outdoor[i] > airTemp - closeThreshold - solarPenalty { isOpen = false }
            } else {
                if series.outdoor[i] < airTemp - openThreshold - solarPenalty { isOpen = true }
            }
            open.append(isOpen)
            if i == n - 1 { break }

            let gains = internalGains + (isOpen ? 1 : shadeFactor) * solar
            let airOutdoorConductance = envelope + (isOpen ? ventilationConductance : 0)
            for _ in 0 ..< substeps {
                let dAir = (dt / airNodeCapacity)
                    * (airOutdoorConductance * (series.outdoor[i] - airTemp)
                        + airMassCoupling * (massTemp - airTemp)
                        + gains)
                let dMass = (dt / massCapacity) * (airMassCoupling * (airTemp - massTemp))
                airTemp += dAir
                massTemp += dMass
            }
            indoor.append(airTemp)
        }
        return Result(indoor: indoor, isOpen: open)
    }

    /// Gain au moment le plus chaud : de combien l'intérieur reste sous
    /// l'extérieur à l'index `peakIndex`.
    static func peakDrop(
        series: WeatherSeries,
        indoorNow: Double,
        inertia: WallInertia,
        ventilation: Ventilation,
        exposure: Exposure,
        peakIndex: Int
    ) -> Double {
        let result = simulate(
            series: series, indoorNow: indoorNow,
            inertia: inertia, ventilation: ventilation, exposure: exposure
        )
        guard result.indoor.indices.contains(peakIndex) else { return 0 }
        return max(0, series.outdoor[peakIndex] - result.indoor[peakIndex])
    }

    private static func bell(_ hour: Double, peak: Double, width: Double) -> Double {
        let x = abs(hour - peak)
        guard x < width else { return 0 }
        let c = cos(.pi / 2 * x / width)
        return c * c
    }
}
