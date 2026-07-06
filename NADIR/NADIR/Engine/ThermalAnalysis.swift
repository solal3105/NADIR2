import Foundation

/// Décomposition additive du gain au plus chaud :
/// base + murs + ventilation + synergie = total.
struct EffectBreakdown: Equatable {
    /// Ouvrir au bon moment, même en logement défavorable.
    var base: Double
    /// Apport propre des murs (vs légers).
    var walls: Double
    /// Apport propre de la ventilation (vs faible).
    var ventilation: Double
    /// Ce que murs et ventilation font ensemble en plus.
    var synergy: Double
    /// Au plus chaud, de combien l'intérieur reste sous l'extérieur.
    var total: Double

    /// La synergie n'est affichée que si elle est perceptible.
    var showsSynergy: Bool { synergy >= 0.15 }
}

/// Résultat complet d'une simulation : créneaux d'ouverture conseillés,
/// repères du graphe et chiffres du verdict.
struct ThermalAnalysis: Equatable {
    let series: WeatherSeries
    let indoorNow: Double
    let result: ThermalModel.Result
    /// Créneaux d'ouverture conseillés (index de la série, bornes incluses).
    let runs: [ClosedRange<Int>]
    /// Index du minimum extérieur.
    let coolestIndex: Int
    /// Index du pic pertinent : le plus chaud APRÈS le début du premier
    /// créneau — celui que la nuit peut encore influencer.
    let peakIndex: Int
    /// Index du minimum intérieur simulé.
    let indoorMinIndex: Int
    let breakdown: EffectBreakdown

    /// `series` doit déjà être fenêtrée (voir `WeatherSeries.window`).
    init(
        series: WeatherSeries,
        indoorNow: Double,
        inertia: WallInertia,
        ventilation: Ventilation,
        exposure: Exposure
    ) {
        self.series = series
        self.indoorNow = indoorNow

        let result = ThermalModel.simulate(
            series: series, indoorNow: indoorNow,
            inertia: inertia, ventilation: ventilation, exposure: exposure
        )
        self.result = result

        var runs: [ClosedRange<Int>] = []
        var start = -1
        for (i, open) in result.isOpen.enumerated() {
            if open {
                if start < 0 { start = i }
            } else if start >= 0 {
                runs.append(start ... i - 1)
                start = -1
            }
        }
        if start >= 0 { runs.append(start ... result.isOpen.count - 1) }
        self.runs = runs

        let outdoor = series.outdoor
        self.coolestIndex = outdoor.indices.min(by: { outdoor[$0] < outdoor[$1] }) ?? 0

        let firstOpen = runs.first?.lowerBound ?? 0
        let peakIndex = (firstOpen ..< outdoor.count)
            .max(by: { outdoor[$0] < outdoor[$1] }) ?? firstOpen
        self.peakIndex = peakIndex

        let indoor = result.indoor
        self.indoorMinIndex = indoor.indices.min(by: { indoor[$0] < indoor[$1] }) ?? 0

        func drop(_ inertia: WallInertia, _ ventilation: Ventilation) -> Double {
            ThermalModel.peakDrop(
                series: series, indoorNow: indoorNow,
                inertia: inertia, ventilation: ventilation, exposure: exposure,
                peakIndex: peakIndex
            )
        }
        let total = max(0, outdoor[peakIndex] - indoor[peakIndex])
        let base = drop(.light, .low)
        let walls = max(0, drop(inertia, .low) - base)
        let vent = max(0, drop(.light, ventilation) - base)
        self.breakdown = EffectBreakdown(
            base: base,
            walls: walls,
            ventilation: vent,
            synergy: max(0, total - base - walls - vent),
            total: total
        )
    }

    /// Fenêtres à ouvrir dès maintenant ?
    var shouldOpenNow: Bool { result.isOpen.first ?? false }

    /// L'intérieur au plus chaud, vs l'extérieur (°C de mieux).
    var coolerAtPeak: Double {
        max(0, series.outdoor[peakIndex] - result.indoor[peakIndex])
    }

    /// Minimum intérieur simulé.
    var indoorMin: Double { result.indoor[indoorMinIndex] }

    /// Air humide pendant les heures d'ouverture conseillées
    /// (point de rosée moyen > 16 °C) : aérer, mais pas trop longtemps.
    var humidDuringOpenings: Bool {
        let dews = zip(result.isOpen, series.dewPoint).filter(\.0).map(\.1)
        guard !dews.isEmpty else { return false }
        return dews.reduce(0, +) / Double(dews.count) > 16
    }

    /// Début / fin du premier créneau, en dates réelles
    /// (la fin est l'heure qui suit la dernière heure ouverte).
    var firstWindow: (start: Date, end: Date)? {
        guard let first = runs.first else { return nil }
        return (
            start: series.times[first.lowerBound],
            end: series.times[first.upperBound].addingTimeInterval(3600)
        )
    }

    /// Heure de fin exclusive d'un créneau, façon « 07h » (heure suivante).
    func endLabel(of run: ClosedRange<Int>) -> String {
        String(format: "%02dh", (series.hour(at: run.upperBound) + 1) % 24)
    }

    /// Créneau formaté « de 22h à 07h ».
    func rangeLabel(of run: ClosedRange<Int>) -> String {
        "de \(series.hourLabel(at: run.lowerBound)) à \(endLabel(of: run))"
    }

    /// Titre du verdict : « Ouvrez jusqu'à 07h », « Ouvrez de 22h à 07h »
    /// ou « Gardez fermé ».
    var verdictTitle: String {
        guard let first = runs.first else { return "Gardez fermé" }
        return shouldOpenNow ? "Ouvrez jusqu'à \(endLabel(of: first))" : "Ouvrez \(rangeLabel(of: first))"
    }

    /// Second créneau éventuel, formaté « de 22h à 07h ».
    var secondWindowLabel: String? {
        runs.count > 1 ? rangeLabel(of: runs[1]) : nil
    }
}
