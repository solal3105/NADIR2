import SwiftUI

/// La température chez vous : le seul réglage qui change d'un jour à
/// l'autre, donc le seul laissé sur l'écran Aujourd'hui.
struct IndoorTemperatureRow: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("Quelle température fait-il chez vous\u{00A0}?")
                    .font(.nadirSans(16, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer(minLength: 0)
                Text(model.indoorLabel)
                    .font(.nadirSans(18, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 0.15), value: model.indoorNow)
            }
            Slider(
                value: Binding(get: { model.indoorNow }, set: { model.setIndoor($0) }),
                in: 8 ... 45,
                step: 0.5
            )
            .tint(.white)
            .accessibilityLabel("Température chez vous")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
    }
}

/// « Votre logement » : la ville, les murs, la façon d'ouvrir, le côté des
/// fenêtres et ce que l'on cherche. Réglé une fois, ouvert en feuille.
struct HomeSettingsSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var city = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Votre logement")
                    .font(.nadirSans(22, weight: .heavy))
                    .tracking(-0.5)
                    .foregroundStyle(.white)
                Spacer()
                Button("OK") { dismiss() }
                    .font(.nadirSans(16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    cityField
                    field(
                        "De quoi sont faits vos murs\u{00A0}?",
                        hint: model.profile.inertia.hint
                    ) {
                        SegmentedRow(
                            options: WallInertia.allCases,
                            label: \.choiceLabel,
                            isSelected: { $0 == model.profile.inertia },
                            select: { model.set(inertia: $0) }
                        )
                    }
                    field(
                        "Comment pouvez-vous ouvrir\u{00A0}?",
                        hint: model.profile.ventilation.hint
                    ) {
                        SegmentedRow(
                            options: Ventilation.allCases,
                            label: \.choiceLabel,
                            isSelected: { $0 == model.profile.ventilation },
                            select: { model.set(ventilation: $0) }
                        )
                    }
                    field(
                        "De quel côté sont vos fenêtres\u{00A0}?",
                        hint: model.profile.exposure.hint
                    ) {
                        SegmentedRow(
                            options: Facade.allCases,
                            label: \.titleLabel,
                            isSelected: { model.profile.exposure.contains($0) },
                            select: { model.toggleExposure($0) }
                        )
                    }
                    field("Que cherchez-vous\u{00A0}?", hint: modeHint) {
                        SegmentedRow(
                            options: AdviceMode.allCases,
                            label: \.choiceLabel,
                            isSelected: { $0 == model.profile.mode },
                            select: { model.set(mode: $0) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.black)
        .presentationBackground(Color.black)
        .preferredColorScheme(.dark)
    }

    private var modeHint: String {
        switch model.profile.mode {
        case .auto:
            let now = model.mode == .air ? "aérer" : "rafraîchir"
            return "NADIR vous aide à rafraîchir dès qu’il fait \(AerationAnalysis.summerDayMax.noDecimal) °C dehors, et à aérer le reste du temps. En ce moment, il vous aide à \(now)."
        case .cool:
            return "NADIR vous dit quand ouvrir pour faire entrer la fraîcheur."
        case .air:
            return "NADIR vous dit quand aérer sans refroidir votre logement."
        }
    }

    private var cityField: some View {
        VStack(alignment: .leading, spacing: 10) {
            question("Votre ville")
            HStack(spacing: 8) {
                TextField(
                    "", text: $city,
                    prompt: Text("Ex. : Lyon").foregroundStyle(Color.nadirFaint)
                )
                .font(.nadirSans(16))
                .foregroundStyle(.white)
                .tint(.white)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit(submitCity)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .border(Color.nadirLine2, width: 1)

                Button(action: submitCity) {
                    Text("Valider")
                        .font(.nadirSans(15, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .frame(height: 46)
                        .background(Color.white)
                }
                .buttonStyle(.plain)
            }

            Button {
                Task { await model.useMyLocation(in: .main) }
            } label: {
                HStack(spacing: 8) {
                    LocatingCrosshair(active: model.isLocating)
                    Text("Utiliser ma position")
                        .font(.nadirSans(15))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .border(Color.nadirLine2, width: 1)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !model.status.isEmpty {
                Text(model.status)
                    .font(.nadirSans(14))
                    .lineSpacing(2)
                    .foregroundStyle(Color.nadirDim)
            }
        }
    }

    private func field<Content: View>(
        _ title: String,
        hint: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            question(title)
                .padding(.bottom, 10)
            content()
            Text(hint)
                .font(.nadirSans(14))
                .lineSpacing(2)
                .foregroundStyle(Color.nadirDim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
    }

    private func question(_ text: String) -> some View {
        Text(text)
            .font(.nadirSans(15, weight: .semibold))
            .foregroundStyle(.white)
    }

    private func submitCity() {
        Task { await model.search(city: city, in: .main) }
    }
}

// MARK: - Libellés

extension AppModel {
    /// « Lyon, murs moyens, fenêtre grande ouverte, exposé sud. »
    var homeSummary: String {
        let place = profile.place.isEmpty ? "ville à indiquer" : profile.place
        let parts = [
            place,
            "murs \(profile.inertia.choiceLabel.lowercased())",
            profile.ventilation.summaryLabel,
            profile.exposure.summaryLabel,
        ]
        return parts.joined(separator: ", ").capitalizedFirst + "."
    }
}

extension WallInertia {
    var choiceLabel: String {
        switch self {
        case .light: "Légers"
        case .medium: "Moyens"
        case .heavy: "Lourds"
        }
    }

    var hint: String {
        switch self {
        case .light: "Cloisons, bois, préfabriqué."
        case .medium: "Brique creuse, parpaing. C’est le cas le plus courant."
        case .heavy: "Pierre, béton, brique pleine."
        }
    }
}

extension Ventilation {
    var choiceLabel: String {
        switch self {
        case .low: "Entrouvert"
        case .medium: "Grand ouvert"
        case .high: "Courant d’air"
        }
    }

    var summaryLabel: String {
        switch self {
        case .low: "fenêtre entrouverte"
        case .medium: "fenêtre grande ouverte"
        case .high: "courant d’air"
        }
    }

    var hint: String {
        switch self {
        case .low: "Une seule fenêtre, entrouverte."
        case .medium: "Une fenêtre grande ouverte."
        case .high: "Plusieurs fenêtres ouvertes, ou un ventilateur."
        }
    }
}

extension AdviceMode {
    var choiceLabel: String {
        switch self {
        case .auto: "Automatique"
        case .cool: "Rafraîchir"
        case .air: "Aérer"
        }
    }
}

extension Facade {
    var hint: String {
        switch self {
        case .north: "Au nord, le soleil n’entre presque pas."
        case .east: "À l’est, le soleil entre le matin."
        case .south: "Au sud, le soleil entre en milieu de journée."
        case .west: "À l’ouest, le soleil entre l’après-midi et le soir."
        }
    }
}

extension Exposure {
    /// Note de traversée quand deux côtés sont sélectionnés.
    var dualNote: String? {
        guard isDual else { return nil }
        return isCrossOpposite
            ? "Logement traversant : en ouvrant des deux côtés, vous faites un vrai courant d’air."
            : "Logement d’angle : en ouvrant des deux côtés, l’air circule mieux."
    }

    var hint: String {
        dualNote ?? "\(primary.hint) Si votre logement est traversant, choisissez deux côtés."
    }

    /// « exposé sud », « traversant est-ouest », « exposé sud et ouest ».
    var summaryLabel: String {
        guard let secondary, isDual else { return "exposé \(primary.label)" }
        return isCrossOpposite
            ? "traversant \(primary.label)-\(secondary.label)"
            : "exposé \(primary.label) et \(secondary.label)"
    }
}
