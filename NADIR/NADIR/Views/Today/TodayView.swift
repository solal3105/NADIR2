import SwiftUI

/// Onglet Aujourd'hui : le conseil et sa phrase d'explication, le graphe,
/// les notifications, la température chez vous, puis votre logement et le
/// détail du chiffre, repliés.
struct TodayView: View {
    @Environment(AppModel.self) private var model
    @State private var showsHomeSettings = false

    var body: some View {
        let analysis = model.analysis
        let aeration = model.aeration
        let playsIntro = model.animatedChartKey != model.chartAnimationKey
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                navigationRow
                verdict(analysis, aeration: aeration)
                    .riseIn(trigger: model.chartAnimationKey, animated: playsIntro, delay: 1.05)
                chart(analysis, bands: aeration.map { [$0.window] })
                if let window = model.alarmWindow {
                    AlarmsSection(window: window, isAiring: aeration != nil)
                }
                IndoorTemperatureRow()
                homeRow
                if let aeration {
                    AerationSection(aeration: aeration)
                } else if analysis.showsBreakdown {
                    FiguresSection(analysis: analysis)
                }
                Color.nadirLine.frame(height: 1)
            }
            .padding(.bottom, 104)
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
        .sheet(isPresented: $showsHomeSettings) {
            HomeSettingsSheet()
        }
    }

    // MARK: - En-tête

    private var navigationRow: some View {
        HStack {
            Text("NADIR")
                .font(.nadirSans(19, weight: .heavy))
                .tracking(0.4)
                .foregroundStyle(.white)
            Spacer()
            Button {
                showsHomeSettings = true
            } label: {
                HStack(spacing: 7) {
                    Circle()
                        .fill(model.series.isDemo ? Color.nadirDim : Color.nadirGo)
                        .frame(width: 7, height: 7)
                    Text(model.series.isDemo ? "Exemple" : model.series.place)
                        .font(.nadirSans(15))
                        .foregroundStyle(Color.nadirSoft)
                        .lineLimit(1)
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Changer de ville")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: - Le conseil

    private func verdict(_ analysis: ThermalAnalysis, aeration: AerationAnalysis?) -> some View {
        let isClosed = aeration == nil && analysis.runs.isEmpty
        return VStack(alignment: .leading, spacing: 0) {
            Text(aeration?.verdictTitle ?? analysis.verdictTitle)
                .font(.nadirSans(38, weight: .heavy))
                .tracking(-1.3)
                .foregroundStyle(isClosed ? Color.nadirHot : Color.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(aeration.map { Self.airLead($0) } ?? Self.coolLead(analysis))
                .font(.nadirSans(17))
                .lineSpacing(3)
                .foregroundStyle(Color.nadirSoft)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)

            if let countdown = countdown(analysis, aeration: aeration) {
                (Text("C’est ") + Text(countdown).fontWeight(.semibold).foregroundColor(.white) + Text("."))
                    .font(.nadirSans(15))
                    .foregroundStyle(Color.nadirDim)
                    .padding(.top, 8)
            }

            if !model.status.isEmpty {
                Text(model.status)
                    .font(.nadirSans(14))
                    .foregroundStyle(Color.nadirDim)
                    .padding(.top, 10)
                    .transition(.opacity)
            }

            if model.series.isDemo {
                Button {
                    showsHomeSettings = true
                } label: {
                    (
                        Text("Ceci est un exemple. ")
                            + Text("Indiquez votre ville").underline().foregroundColor(.white)
                            + Text(" pour avoir votre propre conseil.")
                    )
                    .font(.nadirSans(15))
                    .lineSpacing(2)
                    .foregroundStyle(Color.nadirDim)
                    .multilineTextAlignment(.leading)
                }
                .buttonStyle(.plain)
                .padding(.top, 14)
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.status)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }

    /// « dans 3 h 05 », seulement quand le créneau est à venir.
    private func countdown(_ analysis: ThermalAnalysis, aeration: AerationAnalysis?) -> String? {
        let start: Date?
        if let aeration {
            start = aeration.isNow ? nil : aeration.airing.start
        } else {
            start = analysis.shouldOpenNow ? nil : analysis.firstWindow?.start
        }
        guard let start, start > model.now else { return nil }
        return model.delayLabel(until: start)
    }

    /// La phrase sous le conseil d'été.
    static func coolLead(_ analysis: ThermalAnalysis) -> String {
        guard !analysis.runs.isEmpty else {
            return "Il ne fera pas assez frais dehors dans les prochaines heures pour rafraîchir votre logement. Gardez fenêtres et volets fermés."
        }
        var sentences = [
            analysis.shouldOpenNow
                ? "Il fait déjà plus frais dehors que chez vous."
                : "D’ici là, gardez fenêtres et volets fermés.",
        ]
        let gain = Int(analysis.breakdown.total.rounded())
        if gain >= 1 {
            let moment = analysis.series.momentText(at: analysis.peakIndex).capitalizedFirst
            sentences.append("\(moment), au plus chaud, il devrait faire environ \(gain)\u{00A0}°C de moins chez vous que dehors.")
        }
        if let second = analysis.secondWindowLabel {
            sentences.append("Vous pourrez rouvrir \(second).")
        }
        if analysis.humidDuringOpenings {
            sentences.append("L’air sera humide : n’ouvrez pas plus longtemps que conseillé.")
        }
        return sentences.joined(separator: " ")
    }

    /// La phrase sous le conseil de mi-saison.
    static func airLead(_ aeration: AerationAnalysis) -> String {
        if aeration.isFree {
            return "Il fait aussi doux dehors que chez vous : vous pouvez laisser ouvert aussi longtemps que vous voulez."
        }
        var text = "Ouvrez grand pendant \(aeration.minutes) minutes, puis refermez. C’est le moment le plus doux de la journée, celui où votre logement perdra le moins de chaleur."
        if !aeration.dries {
            text += " L’air du dehors est aussi humide que chez vous : aérer renouvellera l’air, sans l’assécher."
        }
        return text
    }

    // MARK: - Graphe et logement

    private func chart(_ analysis: ThermalAnalysis, bands: [ClosedRange<Int>]?) -> some View {
        ChartView(
            analysis: analysis,
            animationKey: model.chartAnimationKey,
            hasPlayed: model.animatedChartKey == model.chartAnimationKey,
            onPlayed: { model.animatedChartKey = model.chartAnimationKey },
            bands: bands
        )
            .frame(maxWidth: .infinity)
            .background(Color.nadirChartBackground)
            .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
            .overlay(alignment: .bottom) { Color.nadirLine.frame(height: 1) }
    }

    private var homeRow: some View {
        Button {
            showsHomeSettings = true
        } label: {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Votre logement")
                        .font(.nadirSans(16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(model.homeSummary)
                        .font(.nadirSans(14))
                        .lineSpacing(2)
                        .foregroundStyle(Color.nadirDim)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Text("Modifier")
                    .font(.nadirSans(14))
                    .foregroundStyle(Color.nadirSoft)
            }
            .padding(.vertical, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
    }
}
