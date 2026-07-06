import SwiftUI

/// Vos chiffres : décomposition du gain au plus chaud, poste par poste,
/// puis le total — et les notes de contexte (second créneau, humidité, démo).
struct FiguresSection: View {
    @Environment(AppModel.self) private var model
    let analysis: ThermalAnalysis

    /// Échelle des barres, en °C.
    private static let barScale = 8.0

    private var rows: [(label: String, value: Double)] {
        let breakdown = analysis.breakdown
        var rows: [(String, Double)] = [
            ("ouvrir au bon moment", breakdown.base),
            ("murs \(model.profile.inertia.label)", breakdown.walls),
            ("ventilation \(model.profile.ventilation.label)", breakdown.ventilation),
        ]
        if breakdown.showsSynergy {
            rows.append(("les deux combinés", breakdown.synergy))
        }
        return rows
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Text("→").foregroundStyle(.white)
                Text("VOS CHIFFRES")
            }
            .font(.nadirMono(11))
            .tracking(1.3)
            .foregroundStyle(Color.nadirDim)
            .padding(.bottom, 16)

            Text("Au plus chaud de la journée, vous serez plus frais que dehors.")
                .font(.nadirSans(15))
                .lineSpacing(3)
                .foregroundStyle(Color.nadirDim)
                .padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 11) {
                ForEach(rows, id: \.label) { row in
                    effectRow(label: row.label, value: row.value)
                }
            }
            .animation(.easeOut(duration: 0.35), value: analysis.breakdown)

            totalRow
            disclaimer
            notes
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
        .padding(.top, 16)
    }

    private func effectRow(label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(label)
                    .font(.nadirMono(11.5))
                    .foregroundStyle(Color.nadirDim)
                Spacer(minLength: 0)
                Text("\(value.oneDecimal)°C de moins")
                    .font(.nadirMono(12.5))
                    .foregroundStyle(Color.nadirCold)
            }
            GeometryReader { geometry in
                Color.nadirHairline
                    .overlay(alignment: .leading) {
                        Color.nadirCold
                            .frame(width: geometry.size.width * min(1, value / Self.barScale))
                    }
            }
            .frame(height: 3)
        }
    }

    private var totalRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("au total")
                .font(.nadirMono(12))
                .foregroundStyle(.white)
            Spacer(minLength: 0)
            Text("\(analysis.breakdown.total.oneDecimal)°C de moins que dehors")
                .font(.nadirMono(17))
                .foregroundStyle(Color.nadirGo)
        }
        .padding(.top, 11)
        .overlay(alignment: .top) { Color.nadirLine2.frame(height: 1) }
        .padding(.top, 11)
    }

    private var disclaimer: some View {
        Text("Estimation : NADIR ne peut pas connaître toutes les données de votre logement (isolation, vitrage, étage, environnement…). Retenez l'ordre de grandeur, pas la décimale.")
            .font(.nadirMono(10))
            .lineSpacing(4)
            .foregroundStyle(Color.nadirLine2)
            .padding(.top, 12)
    }

    @ViewBuilder private var notes: some View {
        let second = analysis.secondWindowLabel
        let humid = analysis.humidDuringOpenings
        let demo = analysis.series.isDemo
        if second != nil || humid || demo {
            VStack(alignment: .leading, spacing: 10) {
                if let second {
                    Text("Un deuxième créneau s'ouvre \(second).")
                        .foregroundStyle(Color.nadirDim)
                }
                if humid {
                    Text("L'air sera humide : n'ouvrez pas trop longtemps.")
                        .foregroundStyle(Color.nadirFaint)
                }
                if demo {
                    Text("Exemple. Tapez votre ville pour votre créneau réel.")
                        .foregroundStyle(Color.nadirFaint)
                }
            }
            .font(.nadirSans(15))
            .lineSpacing(3)
            .padding(.top, 18)
            .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
            .padding(.top, 24)
        }
    }
}
