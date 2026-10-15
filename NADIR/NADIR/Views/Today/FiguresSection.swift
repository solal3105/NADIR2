import SwiftUI

/// « D’où vient ce chiffre ? » : l'écart prévu au plus chaud, décomposé
/// poste par poste. Replié par défaut.
struct FiguresSection: View {
    @Environment(AppModel.self) private var model
    let analysis: ThermalAnalysis

    /// Échelle des barres, en °C.
    private static let barScale = 8.0

    private var rows: [(label: String, value: Double)] {
        let breakdown = analysis.breakdown
        var rows: [(String, Double)] = [
            ("Ouvrir aux bonnes heures", breakdown.base),
            ("Vos murs \(model.profile.inertia.choiceLabel.lowercased())", breakdown.walls),
            ("Votre façon d’ouvrir", breakdown.ventilation),
        ]
        if breakdown.showsSynergy {
            rows.append(("Les deux ensemble", breakdown.synergy))
        }
        return rows
    }

    var body: some View {
        ExpandableSection(title: "D’où vient ce chiffre\u{00A0}?") {
            VStack(alignment: .leading, spacing: 0) {
                Text("NADIR estime qu’il fera \(analysis.breakdown.total.degreesText) de moins chez vous que dehors \(analysis.series.momentText(at: analysis.peakIndex)). Voici ce qui fait cet écart.")
                    .font(.nadirSans(15))
                    .lineSpacing(3)
                    .foregroundStyle(Color.nadirSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 18)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(rows, id: \.label) { row in
                        BarRow(
                            label: row.label,
                            value: row.value < 0.05 ? "presque rien" : row.value.degreesText,
                            fraction: row.value / Self.barScale
                        )
                    }
                }
                .animation(.easeOut(duration: 0.35), value: analysis.breakdown)

                EstimateNote()
            }
        }
    }
}

extension ThermalAnalysis {
    /// Le détail n'a de sens que s'il y a un créneau et un écart perceptible.
    var showsBreakdown: Bool { !runs.isEmpty && breakdown.total >= 0.5 }
}

/// Une ligne de barre : libellé, valeur en bleu, barre fine dessous.
struct BarRow: View {
    let label: String
    let value: String
    let fraction: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(label)
                    .font(.nadirSans(14))
                    .foregroundStyle(Color.nadirSoft)
                Spacer(minLength: 0)
                Text(value)
                    .font(.nadirSans(14))
                    .monospacedDigit()
                    .foregroundStyle(Color.nadirCold)
            }
            GeometryReader { geometry in
                Color.nadirHairline
                    .overlay(alignment: .leading) {
                        Color.nadirCold
                            .frame(width: geometry.size.width * min(1, max(0, fraction)))
                    }
            }
            .frame(height: 3)
        }
    }
}

/// Rappel que les chiffres sont des estimations.
struct EstimateNote: View {
    var body: some View {
        Text("C’est une estimation. NADIR ne connaît ni l’isolation, ni le vitrage, ni l’étage de votre logement : fiez-vous à l’ordre de grandeur, pas aux décimales.")
            .font(.nadirSans(13))
            .lineSpacing(3)
            .foregroundStyle(Color.nadirDim)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 18)
    }
}
