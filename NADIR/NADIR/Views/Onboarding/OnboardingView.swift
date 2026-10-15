import SwiftUI

/// Onboarding en quatre réglages : ville, murs, façon d'ouvrir, côté des
/// fenêtres. Chaque étape est facultative : « Passer » sort à tout moment.
struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var city = ""

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack { step.transition(.opacity) }
                        .animation(.easeOut(duration: 0.22), value: model.onboardingStep)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            footer
        }
        .background(Color.black)
    }

    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0 ..< 4, id: \.self) { index in
                    Rectangle()
                        .fill(index <= model.onboardingStep ? Color.white : Color.nadirLine)
                        .frame(width: 22, height: 3)
                }
            }
            .animation(.easeOut(duration: 0.2), value: model.onboardingStep)
            Spacer()
            Button {
                model.finishOnboarding()
            } label: {
                Text("Passer")
                    .font(.nadirSans(15))
                    .foregroundStyle(Color.nadirDim)
                    .padding(4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    @ViewBuilder private var step: some View {
        switch model.onboardingStep {
        case 0: cityStep
        case 1: wallsStep
        case 2: ventilationStep
        default: exposureStep
        }
    }

    // MARK: - Étapes

    private var cityStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            title("Où habitez-vous\u{00A0}?", size: 25)
            subtitle("NADIR a besoin de la météo de chez vous pour savoir quand ouvrir vos fenêtres.")
                .padding(.bottom, 24)

            HStack(spacing: 0) {
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
            .padding(.bottom, 10)

            Button {
                Task { await model.useMyLocation(in: .onboarding) }
            } label: {
                HStack(spacing: 7) {
                    LocatingCrosshair(active: model.isLocating)
                    Text("Utiliser ma position")
                        .font(.nadirSans(15))
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .border(Color.nadirLine, width: 1)

            if !model.onboardingStatus.isEmpty {
                Text(model.onboardingStatus)
                    .font(.nadirSans(14))
                    .lineSpacing(3)
                    .foregroundStyle(Color.nadirDim)
                    .padding(.top, 16)
            }
        }
    }

    private var wallsStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            title("De quoi sont faits vos murs\u{00A0}?")
            subtitle("Des murs lourds se réchauffent lentement, et se refroidissent lentement. Si vous ne savez pas, choisissez Moyens.")
                .padding(.bottom, 22)
            VStack(spacing: 8) {
                ChoiceCard(
                    title: "Légers", hint: "Cloisons, bois, préfabriqué",
                    isSelected: model.profile.inertia == .light
                ) { model.set(inertia: .light) }
                ChoiceCard(
                    title: "Moyens", hint: "Brique creuse, parpaing. C’est le cas le plus courant.",
                    isSelected: model.profile.inertia == .medium
                ) { model.set(inertia: .medium) }
                ChoiceCard(
                    title: "Lourds", hint: "Pierre, béton, brique pleine",
                    isSelected: model.profile.inertia == .heavy
                ) { model.set(inertia: .heavy) }
            }
        }
    }

    private var ventilationStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            title("Comment pouvez-vous ouvrir\u{00A0}?")
            subtitle("Plus l’air circule, plus vite votre logement profite de l’air du dehors.")
                .padding(.bottom, 22)
            VStack(spacing: 8) {
                ChoiceCard(
                    title: "Entrouvert", hint: "Une seule fenêtre, entrouverte",
                    isSelected: model.profile.ventilation == .low
                ) { model.set(ventilation: .low) }
                ChoiceCard(
                    title: "Grand ouvert", hint: "Une fenêtre grande ouverte",
                    isSelected: model.profile.ventilation == .medium
                ) { model.set(ventilation: .medium) }
                ChoiceCard(
                    title: "Courant d’air", hint: "Plusieurs fenêtres ouvertes, d’un côté à l’autre du logement",
                    isSelected: model.profile.ventilation == .high
                ) { model.set(ventilation: .high) }
            }
        }
    }

    private var exposureStep: some View {
        let exposure = model.profile.exposure
        return VStack(alignment: .leading, spacing: 0) {
            title("De quel côté sont vos fenêtres\u{00A0}?")
            (
                Text("NADIR saura à quelle heure le soleil entre chez vous. Si votre logement est traversant, ")
                    + Text("choisissez deux côtés").fontWeight(.semibold).foregroundColor(.white)
                    + Text(".")
            )
            .font(.nadirSans(15))
            .lineSpacing(3)
            .foregroundStyle(Color.nadirDim)
            .padding(.bottom, 14)

            VStack(spacing: 8) {
                ChoiceCard(
                    title: "Nord", hint: "Le soleil n’entre presque pas",
                    isSelected: exposure.contains(.north)
                ) { model.toggleExposure(.north) }
                ChoiceCard(
                    title: "Est", hint: "Le soleil entre le matin",
                    isSelected: exposure.contains(.east)
                ) { model.toggleExposure(.east) }
                ChoiceCard(
                    title: "Sud", hint: "Le soleil entre en milieu de journée",
                    isSelected: exposure.contains(.south)
                ) { model.toggleExposure(.south) }
                ChoiceCard(
                    title: "Ouest", hint: "Le soleil entre l’après-midi et le soir",
                    isSelected: exposure.contains(.west)
                ) { model.toggleExposure(.west) }
            }

            if let note = exposure.dualNote {
                HStack(alignment: .top, spacing: 9) {
                    CrossDraftIcon()
                        .padding(.top, 1)
                    Text(note)
                        .font(.nadirSans(12.5))
                        .lineSpacing(3)
                        .foregroundStyle(Color(white: 200 / 255))
                }
                .padding(12)
                .background(Color.nadirGo.opacity(0.07))
                .border(Color.nadirGo.opacity(0.4), width: 1)
                .padding(.top, 16)
            }
        }
    }

    // MARK: - Pied de page

    private var footer: some View {
        HStack(spacing: 10) {
            if model.onboardingStep > 0 {
                Button {
                    model.backOnboarding()
                } label: {
                    Text("Retour")
                        .font(.nadirSans(15))
                        .padding(.horizontal, 20)
                        .frame(height: 48)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .border(Color.nadirLine, width: 1)
            }
            if model.onboardingStep < 3 {
                primaryButton("Suivant") {
                    if model.onboardingStep == 0 {
                        submitCity()
                    } else {
                        model.advanceOnboarding()
                    }
                }
            } else {
                primaryButton("C’est parti") { model.finishOnboarding() }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .overlay(alignment: .top) { Color.nadirLine.frame(height: 1) }
    }

    private func primaryButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.nadirSans(15, weight: .bold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.white)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func submitCity() {
        Task { await model.search(city: city, in: .onboarding) }
    }

    private func title(_ text: String, size: CGFloat = 23) -> some View {
        Text(text)
            .font(.nadirSans(size, weight: .heavy))
            .tracking(size * -0.02)
            .foregroundStyle(.white)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 10)
    }

    private func subtitle(_ text: String) -> some View {
        Text(text)
            .font(.nadirSans(15))
            .lineSpacing(3)
            .foregroundStyle(Color.nadirDim)
    }
}
