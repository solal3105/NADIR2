import SwiftUI

/// Onglet Aujourd'hui : le verdict, le graphe, les alarmes, vos réglages
/// et vos chiffres.
struct TodayView: View {
    @Environment(AppModel.self) private var model
    @State private var city = ""

    var body: some View {
        let analysis = model.analysis
        let playsIntro = model.animatedChartKey != model.chartAnimationKey
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                navigationRow
                verdict(analysis)
                    .riseIn(trigger: model.chartAnimationKey, animated: playsIntro, delay: 1.05)
                locationControl
                chart(analysis)
                if let window = model.alarmWindow {
                    AlarmsSection(window: window)
                }
                ControlsSection()
                FiguresSection(analysis: analysis)
            }
            .padding(.bottom, 104)
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
    }

    private var navigationRow: some View {
        HStack {
            Text("NADIR")
                .font(.nadirSans(19, weight: .heavy))
                .tracking(0.4)
                .foregroundStyle(.white)
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(model.series.isDemo ? Color.nadirDim : Color.nadirGo)
                    .frame(width: 7, height: 7)
                Text(model.series.place.uppercased())
                    .font(.nadirMono(11))
                    .tracking(0.33)
                    .foregroundStyle(Color.nadirDim)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private func verdict(_ analysis: ThermalAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "Le verdict")
                .padding(.bottom, 14)
            Text(analysis.verdictTitle.uppercased())
                .font(.nadirSans(42, weight: .heavy))
                .tracking(-1.7)
                .lineSpacing(-4)
                .foregroundStyle(analysis.runs.isEmpty ? Color.nadirHot : Color.white)
                .fixedSize(horizontal: false, vertical: true)
            if analysis.runs.isEmpty {
                Text("Restez fermé. Attendez une nuit plus fraîche.")
                    .font(.nadirMono(12.5))
                    .lineSpacing(3)
                    .foregroundStyle(Color.nadirDim)
                    .padding(.top, 16)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 20)
    }

    private var locationControl: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Button {
                    Task { await model.useMyLocation(in: .main) }
                } label: {
                    HStack(spacing: 7) {
                        LocatingCrosshair(active: model.isLocating)
                        Text("MA POSITION")
                            .font(.nadirMono(11))
                            .tracking(0.33)
                    }
                    .padding(.horizontal, 14)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)

                Color.nadirLine.frame(width: 1)

                TextField(
                    "", text: $city,
                    prompt: Text("votre ville").foregroundStyle(Color.nadirFaint)
                )
                .font(.nadirSans(15))
                .foregroundStyle(.white)
                .tint(.white)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit(submitCity)
                .padding(.horizontal, 12)

                Color.nadirLine.frame(width: 1)

                Button(action: submitCity) {
                    Text("→")
                        .font(.nadirSans(18))
                        .padding(.horizontal, 18)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .accessibilityLabel("Valider")
            }
            .frame(height: 48)
            .border(Color.nadirLine, width: 1)

            if !model.status.isEmpty {
                Text(model.status)
                    .font(.nadirMono(11))
                    .lineSpacing(3)
                    .foregroundStyle(Color.nadirDim)
                    .padding(.top, 9)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.status)
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    private func chart(_ analysis: ThermalAnalysis) -> some View {
        ChartView(
            analysis: analysis,
            animationKey: model.chartAnimationKey,
            hasPlayed: model.animatedChartKey == model.chartAnimationKey,
            onPlayed: { model.animatedChartKey = model.chartAnimationKey }
        )
            .frame(maxWidth: .infinity)
            .background(Color.nadirChartBackground)
            .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
            .overlay(alignment: .bottom) { Color.nadirLine.frame(height: 1) }
    }

    private func submitCity() {
        Task { await model.search(city: city, in: .main) }
    }
}
