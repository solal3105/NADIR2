import SwiftUI

/// « Pourquoi à cette heure-là ? » : ce que coûte l'aération au plus doux,
/// comparée au plus frais, et la vapeur évacuée. Replié par défaut.
struct AerationSection: View {
    let aeration: AerationAnalysis

    /// Échelle des barres, en °C.
    private var barScale: Double { max(3, aeration.coldestDipDuring) }

    private var rows: [(label: String, value: Double)] {
        let series = aeration.series
        var rows: [(String, Double)] = [
            ("Aérer à \(series.hourText(at: aeration.bestIndex))", aeration.dipDuring),
        ]
        if aeration.coldestIndex != aeration.bestIndex,
           aeration.coldestDipDuring > aeration.dipDuring + 0.1 {
            rows.append((
                "Aérer à \(series.hourText(at: aeration.coldestIndex)), au plus frais",
                aeration.coldestDipDuring
            ))
        }
        return rows
    }

    private var intro: String {
        if aeration.isFree {
            return "Il fait aussi doux dehors que chez vous : aérer ne refroidit pas votre logement."
        }
        if aeration.dipDuring < 0.3 {
            return "Pendant les \(aeration.minutes) minutes d’aération, l’air de la pièce ne se refroidit presque pas : à cette heure-là, le soleil et vos murs compensent."
        }
        let after = aeration.dipAfter < 0.05
            ? "il n’en reste presque rien"
            : "il n’en reste que \(aeration.dipAfter.degreesText)"
        return "Pendant les \(aeration.minutes) minutes d’aération, l’air de la pièce perd environ \(aeration.dipDuring.degreesText). Une heure plus tard, \(after) : vos murs, restés chauds, ont réchauffé l’air."
    }

    private var more: String {
        var text = aeration.dries
            ? "Chaque aération évacue environ \(max(10, Int((aeration.waterGrams / 10).rounded()) * 10)) g d’eau, ce qui limite l’humidité et la condensation."
            : "Aujourd’hui, l’air du dehors n’est pas plus sec que chez vous : l’aération renouvelle l’air, sans l’assécher."
        if aeration.minutes >= 15 {
            text += " Si vous pouvez ouvrir plus grand, faites-le : l’air se renouvelle plus vite, et vos murs refroidissent moins."
        }
        return text
    }

    var body: some View {
        ExpandableSection(title: "Pourquoi à cette heure-là\u{00A0}?") {
            VStack(alignment: .leading, spacing: 0) {
                paragraph(intro)
                    .padding(.bottom, 18)

                if !aeration.isFree {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(rows, id: \.label) { row in
                            BarRow(
                                label: row.label,
                                value: row.value < 0.05 ? "presque rien" : "−\(row.value.degreesText)",
                                fraction: row.value / barScale
                            )
                        }
                    }
                    .padding(.bottom, 18)
                }

                paragraph(more)
                EstimateNote()
            }
        }
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(.nadirSans(15))
            .lineSpacing(3)
            .foregroundStyle(Color.nadirSoft)
            .fixedSize(horizontal: false, vertical: true)
    }
}
