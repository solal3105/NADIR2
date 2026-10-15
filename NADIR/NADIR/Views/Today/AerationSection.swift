import SwiftUI

/// Vos chiffres, mi-saison : ce que coûte l'aération au plus doux, comparée
/// au plus frais, et la vapeur évacuée — puis les notes de contexte.
struct AerationSection: View {
    let aeration: AerationAnalysis

    /// Échelle des barres, en °C.
    private var barScale: Double { max(3, aeration.coldestDipDuring) }

    private var rows: [(label: String, value: Double)] {
        let series = aeration.series
        var rows: [(String, Double)] = [
            ("au plus doux (\(series.hourLabel(at: aeration.bestIndex))), le temps d'aérer", aeration.dipDuring),
            ("une heure après, les murs ont rendu la chaleur", aeration.dipAfter),
        ]
        if aeration.coldestIndex != aeration.bestIndex,
           aeration.coldestDipDuring > aeration.dipDuring + 0.1 {
            rows.append((
                "au plus frais (\(series.hourLabel(at: aeration.coldestIndex))), le temps d'aérer",
                aeration.coldestDipDuring
            ))
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

            Text("Aérer au plus doux renouvelle l'air sans vider vos murs de leur chaleur : l'air se réchauffe vite au contact des murs.")
                .font(.nadirSans(15))
                .lineSpacing(3)
                .foregroundStyle(Color.nadirDim)
                .padding(.bottom, 20)

            VStack(alignment: .leading, spacing: 11) {
                ForEach(rows, id: \.label) { row in
                    dipRow(label: row.label, value: row.value)
                }
            }

            totalRow
            disclaimer
            notes
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
        .padding(.top, 16)
    }

    private func dipRow(label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(label)
                    .font(.nadirMono(11.5))
                    .foregroundStyle(Color.nadirDim)
                Spacer(minLength: 0)
                Text(value < 0.05 ? "presque rien" : "−\(value.oneDecimal) °C dans l'air")
                    .font(.nadirMono(12.5))
                    .foregroundStyle(Color.nadirCold)
            }
            GeometryReader { geometry in
                Color.nadirHairline
                    .overlay(alignment: .leading) {
                        Color.nadirCold
                            .frame(width: geometry.size.width * min(1, value / barScale))
                    }
            }
            .frame(height: 3)
        }
    }

    private var totalRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("vapeur évacuée")
                .font(.nadirMono(12))
                .foregroundStyle(.white)
            Spacer(minLength: 0)
            Text(aeration.dries
                ? "≈ \(Int((aeration.waterGrams / 10).rounded()) * 10) g d'eau en moins"
                : "rien : l'air du dehors est aussi humide")
                .font(.nadirMono(17))
                .foregroundStyle(Color.nadirGo)
        }
        .padding(.top, 11)
        .overlay(alignment: .top) { Color.nadirLine2.frame(height: 1) }
        .padding(.top, 11)
    }

    private var disclaimer: some View {
        Text("Estimation : NADIR suppose un logement un peu humide (60 % d'humidité) qui tient sa température. Retenez l'ordre de grandeur, pas la décimale.")
            .font(.nadirMono(10))
            .lineSpacing(4)
            .foregroundStyle(Color.nadirLine2)
            .padding(.top, 12)
    }

    @ViewBuilder private var notes: some View {
        let humid = !aeration.dries
        let slow = aeration.minutes >= 15
        let demo = aeration.series.isDemo
        if humid || slow || demo {
            VStack(alignment: .leading, spacing: 10) {
                if humid {
                    Text("L'air du dehors est aussi humide que chez vous : aérez quand même pour renouveler l'air, mais ça n'asséchera pas le logement.")
                        .foregroundStyle(Color.nadirDim)
                }
                if slow {
                    Text("Ouvrez plus grand si vous pouvez : un courant d'air renouvelle l'air en 5 min, et refroidit moins les murs.")
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
