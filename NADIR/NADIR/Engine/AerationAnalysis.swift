import Foundation

/// Aération de mi-saison : automne, hiver, printemps, on n'ouvre plus pour
/// rafraîchir mais pour renouveler l'air et chasser l'humidité. Le bon
/// moment est le plus doux de la journée (moins de chaleur perdue), si
/// l'air du dehors est plus sec que celui de chez vous.
///
/// Même modèle deux nœuds que l'été : l'aération refroidit vite l'AIR,
/// puis les murs, restés chauds, le réchauffent une fois refermé.
/// Hypothèses : logement un peu humide (60 % d'humidité relative) qui
/// tient sa température au moment d'aérer. À titre indicatif.
struct AerationAnalysis: Equatable {
    /// Au-delà de 25 °C dehors (« journée estivale » de Météo-France), le
    /// mode automatique rafraîchit ; en dessous, il conseille d'aérer.
    static let summerDayMax: Double = 25
    /// Humidité relative supposée chez vous.
    static let indoorHumidity: Double = 0.6
    /// Heures éveillées où l'on propose d'aérer (heure locale, incluses).
    static let airingHours = 8 ... 21
    /// Le créneau regroupe les heures à moins de 1 °C du plus doux.
    static let airingSpread: Double = 1
    /// Vapeur évacuée en dessous de laquelle l'air du dehors n'assèche pas, g.
    static let dryingMinGrams: Double = 5

    let series: WeatherSeries
    /// Créneau conseillé (index de la série, bornes incluses).
    let window: ClosedRange<Int>
    /// Le moment le plus doux du créneau.
    let bestIndex: Int
    /// Durée d'aération conseillée, en minutes.
    let minutes: Int
    /// Refroidissement de l'air le temps d'aérer, au plus doux, °C.
    let dipDuring: Double
    /// Refroidissement restant une heure après avoir refermé, °C.
    let dipAfter: Double
    /// Pour comparer : le plus frais des heures éveillées, et la même
    /// aération à ce moment-là.
    let coldestIndex: Int
    let coldestDipDuring: Double
    /// Vapeur évacuée par l'aération, g (0 si l'air du dehors n'assèche pas).
    let waterGrams: Double
    /// L'air du dehors assèche le logement.
    let dries: Bool
    /// Dehors aussi doux que chez vous : aérer ne coûte rien.
    let isFree: Bool

    /// `series` doit déjà être fenêtrée (voir `WeatherSeries.window`).
    init(
        series: WeatherSeries,
        indoorNow: Double,
        inertia: WallInertia,
        ventilation: Ventilation,
        exposure: Exposure
    ) {
        self.series = series
        let n = min(24, series.count)
        let outdoor = series.outdoor
        let rate = Self.airChangeRate(ventilation: ventilation, exposure: exposure)
        let minutes = min(15, max(5, Int((60 / rate).rounded())))
        self.minutes = minutes
        let renewed = 1 - exp(-rate * Double(minutes) / 60)
        let indoorDewPoint = Self.dewPoint(temperature: indoorNow, humidity: Self.indoorHumidity)

        func water(at i: Int) -> Double {
            (Self.vaporDensity(dewPoint: indoorDewPoint, temperature: indoorNow)
                - Self.vaporDensity(dewPoint: series.dewPoint[i], temperature: indoorNow))
                * ThermalModel.volume * renewed
        }

        var candidates = (0 ..< n).filter { Self.airingHours.contains(series.hour(at: $0)) }
        if candidates.isEmpty { candidates = Array(0 ..< n) }
        let drying = candidates.filter { water(at: $0) >= Self.dryingMinGrams }
        let pool = drying.isEmpty ? candidates : drying
        let inPool = Set(pool)

        // Le plus doux ; à 0,5 °C près, le plus tôt (inutile d'attendre demain).
        let warmest = pool.map { outdoor[$0] }.max() ?? outdoor[0]
        let best = pool.first { outdoor[$0] >= warmest - 0.5 } ?? 0
        self.bestIndex = best
        // Créneau : heures contiguës autour, à moins de `airingSpread` du plus doux.
        let floor = min(outdoor[best], warmest - Self.airingSpread)
        var a = best, b = best
        while inPool.contains(a - 1), outdoor[a - 1] >= floor { a -= 1 }
        while inPool.contains(b + 1), outdoor[b + 1] >= floor { b += 1 }
        self.window = a ... b

        func dip(at i: Int) -> (during: Double, after: Double) {
            Self.airingDip(
                series: series, index: i, indoorNow: indoorNow,
                inertia: inertia, ventilation: ventilation, exposure: exposure, minutes: minutes
            )
        }
        let bestDip = dip(at: best)
        self.dipDuring = bestDip.during
        self.dipAfter = bestDip.after

        let coldest = candidates.min { outdoor[$0] < outdoor[$1] } ?? best
        self.coldestIndex = coldest
        self.coldestDipDuring = dip(at: coldest).during

        let grams = water(at: best)
        self.dries = grams >= Self.dryingMinGrams
        self.waterGrams = max(0, grams)
        self.isFree = outdoor[best] >= indoorNow
    }

    /// Le créneau a déjà commencé.
    var isNow: Bool { window.lowerBound == 0 }

    /// Moins de 24 h devant nous : une heure de début « plus tôt » que
    /// maintenant est forcément demain.
    var isTomorrow: Bool {
        !isNow && series.hour(at: window.lowerBound) < series.hour(at: 0)
    }

    /// Titre du verdict : « Aérez jusqu'à 17h », « Aérez de 14h à 17h »
    /// ou « Aérez demain de 14h à 17h ».
    var verdictTitle: String {
        let end = String(format: "%02dh", (series.hour(at: window.upperBound) + 1) % 24)
        if isNow { return "Aérez jusqu'à \(end)" }
        let day = isTomorrow ? "demain " : ""
        return "Aérez \(day)de \(series.hourLabel(at: window.lowerBound)) à \(end)"
    }

    /// Le moment d'aérer (début du créneau) et celui de refermer.
    var airing: (start: Date, end: Date) {
        let start = series.times[window.lowerBound]
        return (start, start.addingTimeInterval(Double(minutes) * 60))
    }

    // MARK: - Physique

    /// Mode effectif : « auto » suit la météo des 24 h à venir.
    static func resolve(_ mode: AdviceMode, series: WeatherSeries) -> AdviceMode {
        guard mode == .auto else { return mode }
        let maximum = series.outdoor.prefix(24).max() ?? 0
        return maximum >= summerDayMax ? .cool : .air
    }

    /// Renouvellements d'air par heure fenêtres ouvertes, courant d'air compris.
    static func airChangeRate(ventilation: Ventilation, exposure: Exposure) -> Double {
        let crossMultiplier = exposure.isDual ? (exposure.isCrossOpposite ? 1.8 : 1.5) : 1.0
        return ventilation.airChangesPerHour * crossMultiplier
    }

    /// Pression de vapeur saturante (Magnus), hPa.
    static func saturationPressure(_ temperature: Double) -> Double {
        6.112 * exp(17.62 * temperature / (243.12 + temperature))
    }

    /// Point de rosée d'un air à `temperature` et `humidity` (0–1).
    static func dewPoint(temperature: Double, humidity: Double) -> Double {
        let g = log(humidity) + 17.62 * temperature / (243.12 + temperature)
        return 243.12 * g / (17.62 - g)
    }

    /// Vapeur contenue dans 1 m³ d'air de point de rosée donné, porté à
    /// `temperature`, g/m³.
    static func vaporDensity(dewPoint: Double, temperature: Double) -> Double {
        216.7 * saturationPressure(dewPoint) / (temperature + 273.15)
    }

    /// Refroidissement dû à une aération de `minutes` à l'index `index` :
    /// aération puis fenêtres refermées une heure, comparé au logement
    /// resté fermé. Le logement est supposé à `indoorNow` au moment d'aérer.
    static func airingDip(
        series: WeatherSeries,
        index: Int,
        indoorNow: Double,
        inertia: WallInertia,
        ventilation: Ventilation,
        exposure: Exposure,
        minutes: Int
    ) -> (during: Double, after: Double) {
        typealias M = ThermalModel
        let envelope = M.envelopeLoss * (exposure.isDual ? 1.15 : 1)
        let massCapacity = inertia.kappa * M.floorArea
        let ventilationConductance = M.airHeatCapacityPerVolume
            * airChangeRate(ventilation: ventilation, exposure: exposure) * M.volume / 3600
        let outdoor = series.outdoor[index]
        let solar = M.solarGains(hour: series.hour(at: index), exposure: exposure)
        let closedGains = M.internalGains + M.shadeFactor * solar
        let massStart = indoorNow
            - (envelope * (outdoor - indoorNow) + closedGains) / M.airMassCoupling
        let dt = 60.0

        func run(openMinutes: Int) -> (atClose: Double, end: Double) {
            var air = indoorNow, mass = massStart
            var atClose = air
            for m in 0 ..< minutes + 60 {
                let open = m < openMinutes
                let gains = M.internalGains + (open ? 1 : M.shadeFactor) * solar
                let conductance = envelope + (open ? ventilationConductance : 0)
                let dAir = (dt / M.airNodeCapacity)
                    * (conductance * (outdoor - air) + M.airMassCoupling * (mass - air) + gains)
                let dMass = (dt / massCapacity) * (M.airMassCoupling * (air - mass))
                air += dAir
                mass += dMass
                if m == minutes - 1 { atClose = air }
            }
            return (atClose, air)
        }
        let aired = run(openMinutes: minutes)
        let closed = run(openMinutes: 0)
        return (max(0, closed.atClose - aired.atClose), max(0, closed.end - aired.end))
    }
}
